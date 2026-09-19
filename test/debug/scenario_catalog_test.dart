import 'package:flutter_test/flutter_test.dart';

import 'package:blocos/debug/scenario_catalog.dart';
import 'package:blocos/game/board_script.dart';

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
}
