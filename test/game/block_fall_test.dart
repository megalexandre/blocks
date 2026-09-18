import 'package:flutter_test/flutter_test.dart';

import 'package:blocos/game/block_grid.dart';

void main() {
  test(
    'bloco caindo anima suavemente entre linhas, sem pular direto de uma '
    'para a outra',
    () {
      // A interpolação da queda é do BlockGrid: applyGravityStep soma o
      // rastro e easeFalls derrete. Testar aqui, direto no dono, dispensa
      // subir Flame — a camada de regras é Dart puro.
      final grid = BlockGrid(columns: 6, rowCount: 13);

      int? col;
      for (var c = 0; c < grid.columns; c++) {
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

      const passo = 0.035; // BoardComponent.fallStepSeconds
      grid.applyGravityStep();
      expect(
        fallingBlock.fallOffset,
        1,
        reason: 'cair uma linha tem que somar exatamente 1 de rastro',
      );

      var viuNoMeio = false;
      for (var i = 0; i < 200; i++) {
        grid.easeFalls(0.008, fallStepSeconds: passo);
        if (fallingBlock.fallOffset > 0.01 && fallingBlock.fallOffset < 0.99) {
          viuNoMeio = true;
        }
      }

      expect(
        viuNoMeio,
        isTrue,
        reason:
            'fallOffset nunca ficou entre 0 e 1 — a queda pulou de linha em '
            'linha em vez de interpolar',
      );
      expect(fallingBlock.fallOffset, 0, reason: 'o rastro tem que zerar');
      expect(grid.atIndex(grid.floorIndex, col), same(fallingBlock));
    },
  );
}
