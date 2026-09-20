import 'package:flutter_test/flutter_test.dart';

import 'package:blocos/debug/scenario_catalog.dart';
import 'package:blocos/game/board_script.dart';
import 'package:blocos/game/playfield.dart';

void main() {
  test('todo cenário do catálogo monta sem estourar', () {
    // Um desenho com largura errada ou uma letra que não é cor só falharia ao
    // abrir aquele item do menu. Aqui falha no `flutter test`, que é onde dá
    // para ver.
    expect(scenarioCatalog, isNotEmpty);

    for (final scenario in scenarioCatalog) {
      expect(
        scenario.build,
        returnsNormally,
        reason: 'o cenário "${scenario.name}" não montou',
      );
    }
  });

  test('o desenho de cada cenário cabe no tabuleiro que ele monta', () {
    for (final scenario in scenarioCatalog) {
      final playfield = scenario.build();
      final drawing = scenario.board?.lines ?? const [];
      for (final line in drawing) {
        expect(
          line.length,
          playfield.geometry.columnCount,
          reason: 'linha "$line" do cenário "${scenario.name}"',
        );
      }
      expect(
        drawing.length,
        lessThanOrEqualTo(playfield.geometry.visibleRowCount),
        reason: 'o cenário "${scenario.name}" é mais alto que o tabuleiro',
      );
    }
  });

  test('o tabuleiro montado é o que o desenho pediu', () {
    // Ida e volta pelo formato: garante que `build` aplicou o desenho em vez
    // de deixar a pilha de abertura sorteada.
    for (final scenario in scenarioCatalog) {
      final board = scenario.board;
      if (board == null) {
        continue;
      }
      final described = BoardScript.describe(scenario.build().grid);
      expect(
        described.endsWith(board.lines.join('\n')),
        isTrue,
        reason:
            'o cenário "${scenario.name}" montou um tabuleiro diferente do '
            'desenho:\n$described',
      );
    }
  });

  test('cada cenário tem nome e propósito, que é o que o menu mostra', () {
    for (final scenario in scenarioCatalog) {
      expect(scenario.name.trim(), isNotEmpty);
      expect(
        scenario.purpose.trim(),
        isNotEmpty,
        reason: 'sem propósito, o item do menu não diz o que olhar',
      );
    }
  });

  test('os nomes não se repetem', () {
    final names = scenarioCatalog.map((s) => s.name).toList();
    expect(names.toSet(), hasLength(names.length));
  });

  group('os cenários que sobem terminam sozinhos', () {
    const frame = 1 / 60;

    /// Roda sem jogador até a partida acabar, e devolve em quantos segundos.
    double? timeToGameOver(Playfield playfield, {int maxSeconds = 120}) {
      for (var f = 0; f < 60 * maxSeconds; f++) {
        playfield.update(frame);
        if (playfield.isOver) {
          return f / 60;
        }
      }
      return null;
    }

    test('sem a pilha segurada, ninguém joga para sempre', () {
      // Um cenário que sobe e nunca acaba seria um cenário que não dá para
      // usar para estudar a derrota — que é metade do catálogo hoje.
      for (final scenario in scenarioCatalog) {
        final playfield = scenario.build();
        if (playfield.risePaused) {
          continue;
        }
        expect(
          timeToGameOver(playfield),
          isNotNull,
          reason: 'o cenário "${scenario.name}" sobe mas nunca acaba',
        );
      }
    });

    test('a coluna sozinha derruba a partida sem encher o tabuleiro', () {
      // É o que o cenário existe para mostrar: perder é a linha que sai levar
      // **alguma** coisa, não o tabuleiro estar cheio.
      final scenario = scenarioCatalog.firstWhere(
        (s) => s.name == 'Coluna até o teto',
      );
      final playfield = scenario.build();

      final seconds = timeToGameOver(playfield, maxSeconds: 30);
      expect(seconds, isNotNull);
      expect(
        seconds,
        lessThan(10),
        reason: 'um cenário de derrota tem que ser rápido de exercitar',
      );

      final top = playfield.geometry.topRow;
      final occupied = playfield.geometry.columns
          .where((c) => playfield.grid.blockAt(top, c) != null)
          .length;
      expect(
        occupied,
        1,
        reason:
            'a linha que saiu levava uma célula só — e isso bastou para '
            'encerrar a partida',
      );
    });
  });
}
