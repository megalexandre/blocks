import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:blocos/dressing/game_sounds.dart';
import 'package:blocos/scene/wall_component.dart';

void main() {
  group('GameSound: os arquivos existem e estão no bundle', () {
    test('todo som do enum tem arquivo na pasta', () {
      // Renomear um arquivo de som não quebra a compilação: o jogo abre, toca
      // tudo menos aquele, e a única pista é uma linha no log que ninguém
      // está lendo. Aqui o rename falha alto.
      for (final sound in GameSound.values) {
        expect(
          File(sound.assetPath).existsSync(),
          isTrue,
          reason: 'não achei ${sound.assetPath} (som ${sound.name})',
        );
      }
    });

    test('a pasta dos sons está declarada no pubspec', () {
      // Declarar um diretório que não existe derruba o `flutter build` inteiro,
      // e não declarar o que existe deixa o som fora do aplicativo publicado.
      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec, contains('- assets/game_sound/'));
    });

    /// Arquivos que estão na pasta e **não** tocam, de propósito.
    ///
    /// A lista é o registro: enquanto um nome estiver aqui, ele é uma decisão
    /// ou uma pergunta em aberto, não um esquecimento.
    const semUso = {
      // Removido a pedido: a troca era anunciada por um clique de 0,18 s e o
      // estouro vinha meio segundo depois, então toda jogada soava duas vezes.
      // O arquivo fica para o caso de a decisão mudar.
      'blocos_trocando_de_lugar.mp3',
      // Removido a pedido: fanfarra de 1,36 s numa combinação de quatro ou
      // cinco blocos, que acontece o tempo todo, soava como música tocando por
      // cima do jogo. Essas agora se anunciam só pelo estouro.
      'combo_4_ou_5.mp3',
      // Mesma duração e mesmo tamanho do `ao_finalizar_comobo_6_ou_maior.mp3`,
      // conteúdo diferente — parece a segunda versão da mesma geração. Falta
      // ouvir para saber se é a fanfarra da chain, outra tomada da grande, ou
      // o som do fim de jogo.
      'd3417093-36e4-46e4-8248-ede71a530911.mp3',
    };

    test('nenhum arquivo da pasta ficou sem uso nem sem registro', () {
      // O outro lado do teste de cima: som que entrou na pasta e ninguém
      // ligou em evento nenhum é som que o jogador nunca vai ouvir.
      final naPasta = Directory('assets/game_sound')
          .listSync()
          .whereType<File>()
          .map((f) => f.uri.pathSegments.last)
          .where((name) => name.endsWith('.mp3'))
          .toSet();
      final usados = GameSound.values.map((s) => s.fileName).toSet();
      expect(
        naPasta.difference(usados).difference(semUso),
        isEmpty,
        reason: 'arquivo na pasta que nenhum GameSound toca',
      );
      expect(
        semUso.difference(naPasta),
        isEmpty,
        reason: 'registrado como sem uso mas já saiu da pasta — tirar da lista',
      );
    });
  });

  group('a contagem regressiva', () {
    test('dura mais que a porta levando para abrir', () {
      // É o que garante que a contagem termine **depois** de o tabuleiro
      // aparecer. Fosse mais curta, ela acabaria com a porta ainda descendo e
      // a pilha começaria a subir atrás dela.
      expect(
        GameSound.matchStart.seconds,
        greaterThan(WallComponent.slideSeconds),
      );
    });

    test('toda duração declarada é positiva', () {
      // Zero aqui faria a partida começar no mesmo quadro do toque, sem
      // contagem nenhuma — e sem erro, o que é o pior jeito de quebrar.
      for (final sound in GameSound.values) {
        expect(sound.seconds, greaterThan(0), reason: sound.name);
      }
    });
  });

  group('GameSounds: os cortes do combo', () {
    test('o trio comum não faz barulho nenhum', () {
      // Nem estouro ao sumir: o jogador faz dezenas de trincas por partida, e
      // anunciar todas é não anunciar nada.
      expect(GameSounds.audibleCombo, greaterThan(3));
    });

    test('a fanfarra fica bem acima do que só é audível', () {
      // Colados, toda combinação que faz barulho faria música junto — e
      // música em jogada comum vira ruído.
      expect(
        GameSounds.fanfareCombo,
        greaterThan(GameSounds.audibleCombo + 1),
      );
    });
  });
}
