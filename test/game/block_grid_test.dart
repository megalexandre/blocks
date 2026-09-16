import 'package:flutter_test/flutter_test.dart';

import 'package:blocos/game/block.dart';
import 'package:blocos/game/block_grid.dart';

void main() {
  group('BlockGrid.applyGravityStep', () {
    test('cada passo de queda soma 1 ao fallOffset do bloco', () {
      final grid = BlockGrid.empty(columns: 1, rowCount: 4);
      // Piso inerte (índice 3) sustenta a jogável; o bloco em 0 tem dois
      // espaços vazios abaixo antes de pousar em cima do piso.
      grid.place(3, 0, BlockColor.purple);
      grid.place(0, 0, BlockColor.red);
      final block = grid.atIndex(0, 0)!;

      expect(block.fallOffset, 0);

      grid.applyGravityStep();
      expect(grid.atIndex(1, 0), same(block));
      expect(block.fallOffset, 1);

      grid.applyGravityStep();
      expect(grid.atIndex(2, 0), same(block));
      expect(block.fallOffset, 2);

      // Piso alcançado: mais um passo não move nem soma nada.
      grid.applyGravityStep();
      expect(grid.atIndex(2, 0), same(block));
      expect(block.fallOffset, 2);
    });

    test('bloco já apoiado não ganha fallOffset', () {
      final grid = BlockGrid.empty(columns: 1, rowCount: 3);
      grid.place(2, 0, BlockColor.purple);
      grid.place(1, 0, BlockColor.red);
      final block = grid.atIndex(1, 0)!;

      grid.applyGravityStep();
      expect(grid.atIndex(1, 0), same(block));
      expect(block.fallOffset, 0);
    });
  });
}
