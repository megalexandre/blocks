import 'package:flutter_test/flutter_test.dart';

import 'package:blocos/game/board_component.dart';
import 'package:blocos/game/score.dart';
import 'package:blocos/game/stack_raiser.dart';

void main() {
  test(
    'bloco caindo anima suavemente entre linhas, sem pular direto de uma '
    'para a outra',
    () {
      // BoardComponent.update() não toca em nada que dependa do ciclo de vida
      // do Flame (onLoad só rasteriza os glifos, usados apenas no desenho),
      // então dá para chamá-lo direto, sem GameWidget nem tester.pump.
      final board = BoardComponent(stackRaiser: StackRaiser(), score: Score());
      final grid = board.grid;

      int? col;
      for (var c = 0; c < BoardComponent.columns; c++) {
        if (grid.atIndex(grid.floorIndex - 1, c) != null &&
            grid.atIndex(grid.floorIndex, c) != null) {
          col = c;
          break;
        }
      }
      expect(col, isNotNull, reason: 'nenhuma coluna com bloco apoiado achada');

      // Abre um buraco no piso: o bloco de cima fica sem apoio e cai uma
      // linha.
      grid.remove(grid.floorIndex, col!);
      final fallingBlock = grid.atIndex(grid.floorIndex - 1, col)!;

      var sawMidFall = false;
      for (var i = 0; i < 200; i++) {
        board.update(0.008);
        if (fallingBlock.fallOffset > 0.01 && fallingBlock.fallOffset < 0.99) {
          sawMidFall = true;
        }
      }

      expect(
        sawMidFall,
        isTrue,
        reason:
            'fallOffset nunca ficou entre 0 e 1 — a queda pulou de linha em '
            'linha em vez de interpolar',
      );
      expect(fallingBlock.fallOffset, 0);
      expect(grid.atIndex(grid.floorIndex, col), same(fallingBlock));
    },
  );
}
