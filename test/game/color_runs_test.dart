import 'package:flutter_test/flutter_test.dart';

import 'package:blocos/game/model/block.dart';
import 'package:blocos/game/model/block_grid.dart';
import 'package:blocos/game/model/board_geometry.dart';
import 'package:blocos/game/color_runs.dart';
import 'package:blocos/game/model/column.dart';
import 'package:blocos/game/model/row_index.dart';
import 'package:blocos/game/model/scan_axis.dart';

RowIndex row(int value) => RowIndex(value);
Column col(int value) => Column(value);

BlockGrid gridOf({required int columns, required int rows}) =>
    BlockGrid(BoardGeometry(columnCount: columns, visibleRowCount: rows - 1));

void main() {
  group('through: a sequência que passaria por uma célula', () {
    test('uma cor posta entre dois iguais fecha sequência de três', () {
      // O caso que motiva somar os dois lados de uma vez: checar um lado por
      // vez veria dois runs de 1 e deixaria o bloco do meio entrar.
      final grid = gridOf(columns: 5, rows: 3);
      grid.put(row(1), col(0), Block(BlockColor.red));
      grid.put(row(1), col(2), Block(BlockColor.red));
      final runs = ColorRuns.raw(grid);

      expect(
        runs.through(row(1), col(1), BlockColor.red, ScanAxis.horizontal),
        3,
        reason: 'vermelho na coluna 1 juntaria os dois lados num trio',
      );
      expect(
        runs.through(row(1), col(1), BlockColor.blue, ScanAxis.horizontal),
        1,
        reason: 'azul ali não encosta em ninguém',
      );
    });

    test('não lê a célula do meio: mede o buraco, não quem está nele', () {
      // É o que deixa a mesma função servir para o veto ("e se eu puser esta
      // cor aqui?") e para a detecção ("o que está aqui combina?").
      final grid = gridOf(columns: 5, rows: 3);
      grid.put(row(1), col(0), Block(BlockColor.red));
      grid.put(row(1), col(1), Block(BlockColor.green));
      grid.put(row(1), col(2), Block(BlockColor.red));
      final runs = ColorRuns.raw(grid);

      expect(
        runs.through(row(1), col(1), BlockColor.red, ScanAxis.horizontal),
        3,
        reason: 'a pergunta é sobre vermelho, e o verde que está lá não conta',
      );
    });

    test('a contagem para na borda sem estourar', () {
      final grid = gridOf(columns: 3, rows: 3);
      for (final column in grid.geometry.columns) {
        grid.put(row(1), column, Block(BlockColor.red));
      }
      final runs = ColorRuns.raw(grid);

      expect(
        runs.through(row(1), col(0), BlockColor.red, ScanAxis.horizontal),
        3,
      );
      expect(
        runs.through(row(1), col(0), BlockColor.red, ScanAxis.vertical),
        1,
        reason: 'no eixo vertical ele está sozinho',
      );
    });
  });

  group('os dois leitores de cor', () {
    test('o cru conta qualquer bloco; o de jogo exige parado e apoiado', () {
      final grid = gridOf(columns: 3, rows: 4);
      // Linha 3 é a de entrada e serve de piso; a linha 2 fica apoiada nela.
      for (final column in grid.geometry.columns) {
        grid.put(row(3), column, Block(BlockColor.purple));
        grid.put(row(2), column, Block(BlockColor.red));
      }
      // A linha 0 fica com a linha 1 vazia embaixo: está no ar.
      for (final column in grid.geometry.columns) {
        grid.put(row(0), column, Block(BlockColor.green));
      }
      // Um dos apoiados está estourando.
      grid.blockAt(row(2), col(1))!.enter(BlockState.matched);

      final raw = ColorRuns.raw(grid);
      final matchable = ColorRuns.matchable(grid);

      expect(raw.colorAt(row(0), col(0)), BlockColor.green);
      expect(
        matchable.colorAt(row(0), col(0)),
        isNull,
        reason: 'bloco sem apoio está caindo e não pode fechar combinação',
      );
      expect(
        matchable.colorAt(row(2), col(1)),
        isNull,
        reason: 'bloco já em resolução não entra numa combinação nova',
      );
      expect(
        matchable.colorAt(row(2), col(0)),
        BlockColor.red,
        reason: 'parado e apoiado: este combina',
      );
    });

    test('matchedCells ignora a fila que está no ar', () {
      final grid = gridOf(columns: 3, rows: 5);
      // Piso (linha 4) e um trio vermelho apoiado nele (linha 3).
      for (final column in grid.geometry.columns) {
        grid.put(row(4), column, Block(BlockColor.purple));
        grid.put(row(3), column, Block(BlockColor.red));
      }
      // Um trio verde solto na linha 1, com a linha 2 vazia embaixo: no ar.
      for (final column in grid.geometry.columns) {
        grid.put(row(1), column, Block(BlockColor.green));
      }

      final matched = ColorRuns.matchable(grid).matchedCells();

      expect(
        matched.length,
        3,
        reason: 'só o trio apoiado combina; o que está caindo não',
      );
      for (final column in grid.geometry.columns) {
        expect(matched.contains((row: row(3), col: column)), isTrue);
        expect(
          matched.contains((row: row(1), col: column)),
          isFalse,
          reason: 'no original combinação só fecha com bloco assentado',
        );
      }
    });
  });

  test('duas células com linha e coluna trocadas não são a mesma célula', () {
    // Os dois tipos de coordenada apagam para `int` em tempo de execução, e
    // este teste é o que fixa que o conjunto de células continua distinguindo
    // (1,2) de (2,1) mesmo assim.
    final cells = {
      (row: row(1), col: col(2)),
      (row: row(2), col: col(1)),
      (row: row(1), col: col(2)),
    };
    expect(cells.length, 2);
  });
}
