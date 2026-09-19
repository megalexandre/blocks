import 'package:flutter_test/flutter_test.dart';

import 'package:blocos/game/model/block.dart';
import 'package:blocos/game/model/block_grid.dart';
import 'package:blocos/game/model/board_geometry.dart';
import 'package:blocos/game/rules/gravity_system.dart';
import 'package:blocos/game/model/column.dart';
import 'package:blocos/game/model/row_index.dart';

RowIndex row(int value) => RowIndex(value);
Column col(int value) => Column(value);

BlockGrid emptyGrid({required int columns, required int rows}) =>
    BlockGrid(BoardGeometry(columnCount: columns, visibleRowCount: rows - 1));

void main() {
  group('GravitySystem: o passo da queda', () {
    test('cada passo de queda soma 1 ao fallOffset do bloco', () {
      final grid = emptyGrid(columns: 1, rows: 4);
      // Piso inerte (linha 3) sustenta a jogável; o bloco em 0 tem dois
      // espaços vazios abaixo antes de pousar em cima do piso.
      grid.put(row(3), col(0), Block(BlockColor.purple));
      grid.put(row(0), col(0), Block(BlockColor.red));
      final block = grid.blockAt(row(0), col(0))!;
      // dt = 0 avança o passo zero vezes; os passos vêm de `step()`, que
      // adianta exatamente um sem deixar o rastro derreter no caminho.
      final gravity = GravitySystem(grid: grid);
      void step() => gravity.update(GravitySystem.defaultStepSeconds);

      expect(block.fallOffset, 0);

      step();
      expect(grid.blockAt(row(1), col(0)), same(block));
      expect(
        block.fallOffset,
        closeTo(0, 1e-9),
        reason: 'um passo soma 1 de rastro e derrete 1 no mesmo quadro',
      );

      step();
      expect(grid.blockAt(row(2), col(0)), same(block));

      // Piso alcançado: mais um passo não move nem soma nada.
      step();
      expect(grid.blockAt(row(2), col(0)), same(block));
    });

    test('bloco já apoiado não ganha fallOffset', () {
      final grid = emptyGrid(columns: 1, rows: 3);
      grid.put(row(2), col(0), Block(BlockColor.purple));
      grid.put(row(1), col(0), Block(BlockColor.red));
      final block = grid.blockAt(row(1), col(0))!;

      GravitySystem(grid: grid).update(GravitySystem.defaultStepSeconds);
      expect(grid.blockAt(row(1), col(0)), same(block));
      expect(block.fallOffset, 0);
    });
  });
}
