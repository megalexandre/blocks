import 'package:flutter_test/flutter_test.dart';

import 'package:blocos/game/model/block_grid.dart';
import 'package:blocos/game/model/board_geometry.dart';
import 'package:blocos/game/model/column.dart';
import 'package:blocos/game/rules/random_dealer.dart';
import 'package:blocos/game/rules/stack_filler.dart';
import 'package:blocos/game/rules/swap_system.dart';

/// Uma grade já repartida: estes testes são sobre a linha sobreviver ao
/// tempo, e para isso ela precisa ter conteúdo que se possa comparar.
BlockGrid openedGrid() {
  final grid = BlockGrid(BoardGeometry.standard);
  StackFiller.opening(grid: grid, dealer: RandomDealer.seeded(3));
  return grid;
}

void main() {
  group('a linha guardada atravessa a subida da pilha', () {
    test('a mesma BoardRow continua sendo a mesma linha depois do shiftUp', () {
      final grid = openedGrid();
      final floor = grid.geometry.floorRow;
      final row = grid.rowAt(floor);
      final contents = List.of(row.cells);

      grid.shiftUp();

      expect(
        grid.positionOf(row),
        floor.above,
        reason: 'a linha tinha que ter subido exatamente uma posição',
      );
      expect(
        grid.rowAt(floor.above),
        same(row),
        reason: 'a posição nova tem que devolver o mesmo objeto',
      );
      expect(
        row.cells,
        contents,
        reason: 'subir a pilha não pode mexer no conteúdo da linha',
      );
    });

    test('linha que saiu pelo topo não tem mais posição', () {
      final grid = openedGrid();
      final row = grid.rowAt(grid.geometry.topRow);

      expect(grid.positionOf(row), grid.geometry.topRow);
      expect(grid.contains(row), isTrue);

      grid.shiftUp();

      expect(
        grid.positionOf(row),
        isNull,
        reason: 'a linha do topo saiu do tabuleiro — não há posição para ela',
      );
      expect(grid.contains(row), isFalse);
    });

    test('o cursor não escorrega de linha quando a pilha sobe', () {
      // É por isso que o cursor guarda a BoardRow e não um índice: com índice
      // ele ficaria parado na tela enquanto os blocos sobem por baixo dele.
      final grid = openedGrid();
      final controller = SwapSystem(grid: grid);
      final floor = grid.geometry.floorRow;
      final row = grid.rowAt(floor);

      controller.beginDrag(const Column(2), row);
      expect(controller.cursorRow, same(row));

      for (var i = 0; i < 5; i++) {
        grid.shiftUp();
      }

      expect(
        controller.cursorRow,
        same(row),
        reason: 'o cursor largou a linha que o jogador tinha pegado',
      );
      expect(grid.positionOf(controller.cursorRow!), floor.shifted(-5));
    });
  });
}
