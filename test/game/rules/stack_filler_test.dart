import 'package:flutter_test/flutter_test.dart';

import 'package:blocos/game/model/block_grid.dart';
import 'package:blocos/game/model/board_geometry.dart';
import 'package:blocos/game/color_runs.dart';
import 'package:blocos/game/model/scan_axis.dart';
import 'package:blocos/game/rules/random_dealer.dart';
import 'package:blocos/game/rules/stack_filler.dart';

/// Maior sequência da mesma cor que passa pela grade, em qualquer eixo.
///
/// Usa o próprio [ColorRuns] em vez de reimplementar a contagem: era o
/// terceiro lugar do projeto a saber contar iguais em fila, e sumiu junto com
/// os outros dois. Perguntar ao mesmo objeto que o jogo usa também é o que
/// faz o teste falhar se o conceito quebrar, em vez de só discordar dele.
int longestRun(BlockGrid grid) {
  final runs = ColorRuns.raw(grid);
  var longest = 0;
  for (final row in grid.geometry.allRows) {
    for (final col in grid.geometry.columns) {
      final color = runs.colorAt(row, col);
      if (color == null) {
        continue;
      }
      for (final axis in ScanAxis.values) {
        final length = runs.through(row, col, color, axis);
        if (length > longest) {
          longest = length;
        }
      }
    }
  }
  return longest;
}

BlockGrid openedGrid(int seed) {
  final grid = BlockGrid(BoardGeometry.standard);
  StackFiller.opening(grid: grid, dealer: RandomDealer.seeded(seed));
  return grid;
}

void main() {
  test('a pilha de abertura nunca nasce com três iguais em fila', () {
    // Uma partida por semente, e sempre a mesma: com o carteador injetável o
    // teste deixou de precisar rodar trezentas partidas na força bruta
    // torcendo para alguma falhar.
    for (var seed = 0; seed < 50; seed++) {
      expect(
        longestRun(openedGrid(seed)),
        lessThan(ColorRuns.matchLength),
        reason:
            'a partida da semente $seed nasceu com uma combinação pronta — o '
            'veto de cor do StackFiller parou de funcionar',
      );
    }
  });

  test('cada linha que entra por baixo também respeita o veto', () {
    final grid = BlockGrid(BoardGeometry.standard);
    final filler = StackFiller.opening(
      grid: grid,
      dealer: RandomDealer.seeded(7),
    );
    // Cada subida sorteia uma linha nova, e é aí que o veto tem que continuar
    // valendo contra os vizinhos que já estão lá.
    for (var risen = 0; risen < 200; risen++) {
      grid.shiftUp();
      filler.fillIncomingRow();
      expect(
        longestRun(grid),
        lessThan(ColorRuns.matchLength),
        reason: 'a linha $risen entrou fechando uma combinação sozinha',
      );
    }
  });

  test('a mesma semente reparte exatamente o mesmo tabuleiro', () {
    // É o que torna reproduzível qualquer bug que dependa do sorteio.
    final a = openedGrid(42);
    final b = openedGrid(42);
    for (final row in a.geometry.allRows) {
      for (final col in a.geometry.columns) {
        expect(a.blockAt(row, col)?.color, b.blockAt(row, col)?.color);
      }
    }
  });
}
