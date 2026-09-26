import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

import '../game/game_event.dart';

/// Cada som do jogo e o arquivo dele.
///
/// Enum e não um punhado de constantes soltas: o carregamento percorre os
/// valores, então um som novo é uma linha aqui e nada mais — e nenhum fica
/// para trás por esquecimento.
enum GameSound {
  /// A contagem regressiva, tocada **antes** de a partida começar.
  ///
  /// É a única cuja duração o jogo precisa conhecer: a pilha só é solta
  /// quando ela termina. Uma contagem que toca depois do início não conta
  /// nada.
  matchStart('inicio_partida.mp3', seconds: 3.87),

  /// Os blocos começaram a sumir — só quando o grupo é grande o bastante
  /// para valer anúncio.
  pop('blocos_sumindo.mp3', seconds: 1.07),

  /// Uma combinação de seis ou mais.
  comboLarge('ao_finalizar_comobo_6_ou_maior.mp3', seconds: 2.27);

  const GameSound(this.fileName, {required this.seconds});

  final String fileName;

  /// Quanto o arquivo dura, lido do cabeçalho do MP3.
  ///
  /// Aqui, e não perguntado ao motor de áudio, porque o jogo precisa do número
  /// mesmo quando o som **não** tocou: num aparelho mudo a contagem regressiva
  /// continua valendo como espera, e o início da partida não pode depender de
  /// existir alto-falante.
  final double seconds;

  String get assetPath => 'assets/game_sound/$fileName';
}

/// Os sons do jogo: ouve os eventos do quadro e toca o que cada um pede.
///
/// Vestimenta, como o pintor: lê o que aconteceu e nunca mexe no jogo. Por
/// isso reage a eventos e não a estado — o jogo avisa "os blocos começaram a
/// sumir" uma vez, no quadro certo, e aqui só se decide o que isso soa.
///
/// **O jogo nunca espera o áudio.** O motor carrega em paralelo e, até ficar
/// pronto, os sons simplesmente não tocam. A alternativa — esperar o motor
/// antes de montar a cena — deixaria a tela presa se o dispositivo de som
/// demorasse ou não existisse, e é exatamente o que acontece num container
/// sem saída de áudio: o jogo tem que abrir mudo, não travado.
class GameSounds {
  GameSounds._() {
    unawaited(_load());
  }

  /// Uma só por processo. O motor de áudio é global, e o modo de
  /// desenvolvimento recria a cena a cada cenário: carregar de novo a cada
  /// entrada acumularia cópias dos mesmos sons na memória do motor.
  static final GameSounds instance = GameSounds._();

  /// Começa a carregar o motor e os sons, sem esperar.
  ///
  /// Chamado na abertura do aplicativo, e não no primeiro quadro de uma
  /// partida: ligar o motor leva um tempo — mais ainda quando a primeira
  /// tentativa de backend falha — e o primeiro som pode acontecer menos de
  /// meio segundo depois de a partida começar. Sem isto, o som existe mas o
  /// primeiro não sai.
  static void warmUp() => instance;

  /// A partir de quantos blocos a combinação faz algum barulho.
  ///
  /// **Abaixo disso, silêncio.** Um trio é a jogada comum, e o jogador faz
  /// dezenas por partida — anunciar todos é não anunciar nada, e ainda cansa.
  static const int audibleCombo = 4;

  /// E a partir de quantos ela ganha fanfarra.
  ///
  /// Bem acima do audível de propósito: fanfarra é música, e música em jogada
  /// de quatro ou cinco blocos — que acontece o tempo todo — vira ruído. Entre
  /// um corte e outro a combinação se anuncia só pelo estouro.
  static const int fanfareCombo = 6;

  final Map<GameSound, AudioSource> _sources = {};

  void handle(GameEvent event) {
    switch (event) {
      // `count` é o tamanho do grupo que entrou no estouro, que para uma
      // combinação só é o próprio combo — então o mesmo corte serve aqui sem
      // precisar carregar o tamanho de um evento para o outro.
      case PopStarted(:final count) when count >= audibleCombo:
        play(GameSound.pop);
      case MatchCleared(:final comboSize) when comboSize >= fanfareCombo:
        play(GameSound.comboLarge);
      default:
        break;
    }
  }

  /// Toca um som direto.
  ///
  /// Existe para o que **não é evento do jogo**: a partida começando é a cena
  /// abrindo a porta, e a camada de regra não sabe que existe porta nenhuma.
  /// Tudo que o jogo sabe anunciar continua entrando por [handle].
  void play(GameSound sound) {
    final source = _sources[sound];
    if (source == null) {
      return;
    }
    SoLoud.instance.play(source);
  }

  Future<void> _load() async {
    final soloud = SoLoud.instance;
    if (!await _start(soloud)) {
      return;
    }
    // Carregados separados do motor: se o motor subiu e um arquivo não
    // carregou, isso é erro de verdade (caminho errado, asset fora do
    // pubspec), e a mensagem precisa dizer qual.
    for (final sound in GameSound.values) {
      final source = await _loadAsset(soloud, sound.assetPath);
      if (source != null) {
        _sources[sound] = source;
      }
    }
  }

  /// Liga o motor de áudio, e diz se conseguiu.
  ///
  /// Duas tentativas porque o automático não serve a um container. Ele tenta
  /// ALSA antes do PulseAudio, e onde não existe placa de som — não há
  /// `/dev/snd` aqui dentro — a tentativa por ALSA falha e o automático
  /// desiste em vez de seguir para o servidor de áudio, que é justamente o
  /// que está disponível, pelo socket do host montado em `/run/host-pulse`.
  ///
  /// O automático vem primeiro mesmo assim: numa máquina de verdade é ele que
  /// escolhe certo, e uma máquina só com ALSA continua funcionando. O pedido
  /// explícito é a segunda chance, não a regra. Fora do Linux o parâmetro é
  /// ignorado, então a segunda tentativa simplesmente repete a primeira.
  static Future<bool> _start(SoLoud soloud) async {
    for (final backend in LinuxAudioBackend.values.where(
      (b) => b == LinuxAudioBackend.auto || b == LinuxAudioBackend.pulseAudio,
    )) {
      if (soloud.isInitialized) {
        return true;
      }
      try {
        await soloud.init(linuxAudioBackend: backend);
        return true;
      } on Object catch (error) {
        debugPrint('áudio: ${backend.name} não iniciou ($error)');
      }
    }
    // Esperado onde não há saída de som nenhuma. Uma linha no log, e o jogo
    // segue mudo em vez de travar.
    debugPrint('som desligado: nenhum backend de áudio iniciou');
    return false;
  }

  static Future<AudioSource?> _loadAsset(SoLoud soloud, String path) async {
    try {
      return await soloud.loadAsset(path);
    } on Object catch (error) {
      debugPrint('som "$path" não carregou: $error');
      return null;
    }
  }
}
