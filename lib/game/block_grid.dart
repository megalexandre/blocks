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

  /// Quantos iguais em sequência formam uma combinação.
  static const int matchLength = 3;

  final _random = math.Random();

  /// Ordem visual: índice 0 é o topo, o último é a linha que está entrando.
  final List<List<Block?>> _rows = [];

  /// Quantas linhas já saíram pelo topo. É o deslocamento entre id e índice.
  int _consumedRows = 0;

  int get topRowId => _consumedRows;
  int get bottomRowId => _consumedRows + rowCount - 1;

  bool hasRow(int rowId) => rowId >= topRowId && rowId <= bottomRowId;

  /// Índice visual (0 = topo) da linha [rowId].
  int indexOf(int rowId) => rowId - _consumedRows;

  /// Id da linha que está no índice visual [index].
  int rowIdAt(int index) => _consumedRows + index;

  Block? at(int rowId, int col) => _rows[indexOf(rowId)][col];

  /// Leitura pela ordem visual, para quem desenha e para quem resolve
  /// combinações dentro de um mesmo frame.
  Block? atIndex(int index, int col) => _rows[index][col];

  void remove(int index, int col) {
    _rows[index][col] = null;
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
    _rows.add(List<Block?>.filled(columns, null));
    _consumedRows++;
    _fillRow(rowCount - 1);
  }

  /// Existe bloco no ar, ainda caindo. A última linha é o piso, então ela não
  /// conta.
  bool get hasFallingBlocks {
    for (var index = 0; index < rowCount - 1; index++) {
      for (var col = 0; col < columns; col++) {
        if (_rows[index][col] != null && _rows[index + 1][col] == null) {
          return true;
        }
      }
    }
    return false;
  }

  /// Desce em uma linha todo bloco que não tem apoio. A última linha é o piso.
  /// Bloco piscando ou estourando não cai.
  void applyGravityStep() {
    for (var index = _rows.length - 2; index >= 0; index--) {
      for (var col = 0; col < columns; col++) {
        final block = _rows[index][col];
        if (block != null && block.isIdle && _rows[index + 1][col] == null) {
          _rows[index + 1][col] = block;
          _rows[index][col] = null;
        }
      }
    }
  }

  void _fillInitial() {
    _rows
      ..clear()
      ..addAll(List.generate(rowCount, (_) => List<Block?>.filled(columns, null)));

    // A última linha é a que está entrando; a pilha começa na penúltima.
    final floorIndex = rowCount - 2;
    final heights = List.generate(columns, (_) => 3 + _random.nextInt(4));
    // De baixo para cima, para cada bloco já ver os vizinhos que o cercam.
    for (var i = 0; i < heights.reduce(math.max); i++) {
      for (var col = 0; col < columns; col++) {
        if (i < heights[col]) {
          _rows[floorIndex - i][col] = Block(_colorFor(floorIndex - i, col));
        }
      }
    }

    _fillRow(rowCount - 1);
  }

  void _fillRow(int index) {
    for (var col = 0; col < columns; col++) {
      _rows[index][col] = Block(_colorFor(index, col));
    }
  }

  /// Sorteia uma cor que não feche uma combinação de saída. Sem isso o
  /// tabuleiro estouraria sozinho no primeiro frame, e cada linha nova
  /// entraria já estourando.
  BlockColor _colorFor(int index, int col) {
    final candidatas = BlockColor.values
        .where((cor) => !_wouldMatch(index, col, cor))
        .toList();
    final origem = candidatas.isEmpty ? BlockColor.values : candidatas;
    return origem[_random.nextInt(origem.length)];
  }

  bool _wouldMatch(int index, int col, BlockColor cor) =>
      _sameRun(index, col, cor, 0, -1) + 1 >= matchLength ||
      _sameRun(index, col, cor, -1, 0) + 1 >= matchLength ||
      _sameRun(index, col, cor, 1, 0) + 1 >= matchLength;

  /// Quantos blocos da cor [cor] existem em sequência a partir de
  /// (index, col), andando de [stepIndex], [stepCol].
  int _sameRun(int index, int col, BlockColor cor, int stepIndex, int stepCol) {
    var total = 0;
    var i = index + stepIndex;
    var c = col + stepCol;
    while (i >= 0 && i < rowCount && c >= 0 && c < columns) {
      if (_rows[i][c]?.color != cor) {
        break;
      }
      total++;
      i += stepIndex;
      c += stepCol;
    }
    return total;
  }
}
