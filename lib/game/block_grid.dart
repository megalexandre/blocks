import 'dart:math' as math;

import 'block.dart';

/// Estado da grade: quem está em cada célula, e as regras de que a grade é
/// dona — troca e queda. Não sabe nada de pixel nem de tempo.
///
/// Uma linha é endereçada por um `rowId` **estável**: subir a pilha não
/// renumera as linhas existentes, então quem guardar um id continua apontando
/// para a mesma linha. Use [hasRow] antes de ler um id guardado, porque a
/// linha pode já ter saído pelo topo.
class BlockGrid {
  BlockGrid({required this.columns, required this.rowCount}) {
    _fillInitial();
  }

  final int columns;

  /// Linhas mantidas em memória: as visíveis mais a que está entrando por baixo.
  final int rowCount;

  final _random = math.Random();

  /// Ordem visual: índice 0 é o topo, o último é a linha que está entrando.
  final List<List<BlockColor?>> _rows = [];

  /// Quantas linhas já saíram pelo topo. É o deslocamento entre id e índice.
  int _consumedRows = 0;

  int get topRowId => _consumedRows;
  int get bottomRowId => _consumedRows + rowCount - 1;

  bool hasRow(int rowId) => rowId >= topRowId && rowId <= bottomRowId;

  /// Índice visual (0 = topo) da linha [rowId].
  int indexOf(int rowId) => rowId - _consumedRows;

  /// Id da linha que está no índice visual [index].
  int rowIdAt(int index) => _consumedRows + index;

  BlockColor? at(int rowId, int col) => _rows[indexOf(rowId)][col];

  /// Leitura pela ordem visual, para quem desenha.
  BlockColor? atIndex(int index, int col) => _rows[index][col];

  void put(int rowId, int col, BlockColor? block) {
    _rows[indexOf(rowId)][col] = block;
  }

  void swap(int rowId, int colA, int colB) {
    final row = _rows[indexOf(rowId)];
    final held = row[colA];
    row[colA] = row[colB];
    row[colB] = held;
  }

  /// A linha do topo sai, uma nova entra por baixo. Os ids já existentes
  /// continuam valendo.
  void shiftUp() {
    _rows.removeAt(0);
    _rows.add(_randomRow());
    _consumedRows++;
  }

  /// Desce em uma linha todo bloco que não tem apoio. A última linha é o piso.
  void applyGravityStep() {
    for (var index = _rows.length - 2; index >= 0; index--) {
      for (var col = 0; col < columns; col++) {
        if (_rows[index][col] != null && _rows[index + 1][col] == null) {
          _rows[index + 1][col] = _rows[index][col];
          _rows[index][col] = null;
        }
      }
    }
  }

  void _fillInitial() {
    _rows
      ..clear()
      ..addAll(
        List.generate(rowCount, (_) => List<BlockColor?>.filled(columns, null)),
      );

    // A última linha é a que está entrando; a pilha começa na penúltima.
    final floorIndex = rowCount - 2;
    for (var col = 0; col < columns; col++) {
      final height = 3 + _random.nextInt(4);
      for (var i = 0; i < height; i++) {
        _rows[floorIndex - i][col] = _randomBlock();
      }
    }

    _rows[rowCount - 1] = _randomRow();
  }

  List<BlockColor?> _randomRow() =>
      List<BlockColor?>.generate(columns, (_) => _randomBlock());

  BlockColor _randomBlock() =>
      BlockColor.values[_random.nextInt(BlockColor.values.length)];
}
