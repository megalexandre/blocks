import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

import '../game/game_event.dart';

/// Os sons do jogo: ouve os eventos do quadro e toca o que cada um pede.
///
/// Vestimenta, como o pintor: lê o que aconteceu e nunca mexe no jogo. Por
/// isso reage a eventos e não a estado — o jogo avisa "blocos pousaram" uma
/// vez, no quadro certo, e aqui só se decide o que isso soa.
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
  /// tentativa de backend falha — e o primeiro impacto pode acontecer menos
  /// de meio segundo depois de a partida começar. Sem isto, o som existe mas
  /// o primeiro não sai.
  static void warmUp() => instance;

  static const _impactAsset = 'assets/sounds/block_impact.mp3';
  static const _popAsset = 'assets/sounds/pluzze_solved.mp3';

  AudioSource? _impact;
  AudioSource? _pop;

  void handle(GameEvent event) {
    switch (event) {
      case BlocksLanded():
        _play(_impact);
      case PopStarted():
        _play(_pop);
      default:
        break;
    }
  }

  void _play(AudioSource? source) {
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
    _impact = await _loadAsset(soloud, _impactAsset);
    _pop = await _loadAsset(soloud, _popAsset);
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
