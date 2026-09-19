import 'package:flutter_test/flutter_test.dart';

import 'package:blocos/game/block.dart';
import 'package:blocos/game/block_grid.dart';

/// Maior sequência da mesma cor que passa pela grade, em qualquer direção.
int _longestRun(BlockGrid grid) {
  var longest = 0;

  void scan(int index, int col, int stepIndex, int stepCol) {
    var run = 0;
    BlockColor? atual;
    var i = index;
    var c = col;
    while (i >= 0 && i < grid.rowCount && c >= 0 && c < grid.columns) {
      final cor = grid.atIndex(i, c)?.color;
      run = (cor != null && cor == atual) ? run + 1 : 1;
      atual = cor;
      if (cor != null && run > longest) {
        longest = run;
      }
      i += stepIndex;
      c += stepCol;
    }
  }

  for (var index = 0; index < grid.rowCount; index++) {
    scan(index, 0, 0, 1);
  }
  for (var col = 0; col < grid.columns; col++) {
    scan(0, col, 1, 0);
  }
  return longest;
}

void main() {
  test(
    'o carteador nunca reparte um tabuleiro que já nasce estourando',
    () {
      // O sorteio é sem semente de propósito (toda partida é diferente), então
      // a única forma honesta de testar o veto é repetir bastante: uma falha
      // do _wouldMatch apareceria em alguma dessas grades.
      for (var partida = 0; partida < 300; partida++) {
        final grid = BlockGrid(columns: 6, rowCount: 13);
        expect(
          _longestRun(grid),
          lessThan(BlockGrid.matchLength),
          reason:
              'partida $partida nasceu com uma combinação pronta — o veto de '
              'cor do BlockDealer parou de funcionar',
        );
      }
    },
  );

  test('cada linha que entra por baixo também respeita o veto', () {
    final grid = BlockGrid(columns: 6, rowCount: 13);
    // Sobe a pilha muitas vezes: cada shiftUp sorteia uma linha nova, e é aí
    // que o veto tem que continuar valendo contra os vizinhos que já estão lá.
    for (var linha = 0; linha < 200; linha++) {
      grid.shiftUp();
      expect(
        _longestRun(grid),
        lessThan(BlockGrid.matchLength),
        reason: 'a linha $linha entrou fechando uma combinação sozinha',
      );
    }
  });
}
