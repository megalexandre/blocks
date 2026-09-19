import 'package:flutter_test/flutter_test.dart';

import 'package:blocos/game/model/block_grid.dart';
import 'package:blocos/game/model/board_geometry.dart';
import 'package:blocos/game/model/column.dart';
import 'package:blocos/game/rules/gravity_system.dart';
import 'package:blocos/game/rules/random_dealer.dart';
import 'package:blocos/game/rules/stack_filler.dart';

void main() {
  test(
    'bloco caindo anima suavemente entre linhas, sem pular direto de uma '
    'para a outra',
    () {
      // A interpolação da queda é do GravitySystem: ele soma o rastro no
      // passo e derrete no mesmo ritmo. Testar aqui, direto no dono,
      // dispensa subir Flame — a camada de regras é Dart puro.
      // Semeado: a pilha de abertura tem alturas sorteadas, e sem semente o
      // teste dependia de achar uma coluna adequada numa grade diferente a
      // cada execução.
      final grid = BlockGrid(BoardGeometry.standard);
      StackFiller.opening(grid: grid, dealer: RandomDealer.seeded(1));
      final geometry = grid.geometry;
      final floor = geometry.floorRow;

      Column? column;
      for (final candidate in geometry.columns) {
        if (grid.blockAt(floor.above, candidate) != null &&
            grid.blockAt(floor, candidate) != null) {
          column = candidate;
          break;
        }
      }
      expect(
        column,
        isNotNull,
        reason: 'nenhuma coluna com bloco apoiado achada',
      );

      // Abre um buraco no piso: o bloco de cima fica sem apoio e cai uma
      // linha.
      grid.clear(floor, column!);
      final fallingBlock = grid.blockAt(floor.above, column)!;

      // Quadros curtos, como os de verdade: com dt menor que o passo, o
      // rastro derrete só um pedaço por quadro, e é essa sobra que o olho lê
      // como deslizar. Um único update com dt igual ao passo somaria 1 e
      // derreteria 1 na mesma chamada — por isso o teste não observa o
      // rastro cheio, e sim o caminho entre 0 e 1.
      final gravity = GravitySystem(grid: grid);
      var sawMidway = false;
      var peak = 0.0;
      for (var i = 0; i < 200; i++) {
        gravity.update(0.008);
        final offset = fallingBlock.fallOffset;
        if (offset > 0.01 && offset < 0.99) {
          sawMidway = true;
        }
        if (offset > peak) {
          peak = offset;
        }
      }

      expect(
        peak,
        lessThanOrEqualTo(1.0),
        reason: 'o rastro nunca pode passar de uma linha inteira',
      );

      expect(
        sawMidway,
        isTrue,
        reason:
            'fallOffset nunca ficou entre 0 e 1 — a queda pulou de linha em '
            'linha em vez de interpolar',
      );
      expect(fallingBlock.fallOffset, 0, reason: 'o rastro tem que zerar');
      expect(grid.blockAt(floor, column), same(fallingBlock));
    },
  );
}
