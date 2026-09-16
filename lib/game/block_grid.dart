import 'dart:math' as math;

import 'block.dart';

/// Direção de varredura na grade: quanto andar em linha e em coluna por passo.
typedef GridStep = ({int index, int col});

const GridStep _horizontal = (index: 0, col: 1);
const GridStep _vertical = (index: 1, col: 0);

/// Estado da grade: quem está em cada célula, e as regras de que a grade é
/// dona — troca e queda. Não sabe nada de pixel nem de tempo.
///
/// Uma linha é endereçada por um `rowId` **estável**: subir a pilha não
/// renumera as linhas existentes, então quem guardar um id continua apontando
/// para a mesma linha. Use [hasRow] antes de ler um id guardado, porque a
/// linha pode já ter saído pelo topo.
class BlockGrid {

  BlockGrid({required this.columns, required this.rowCount}) {
    _allocateEmptyRows();
    _dealStartingStack();
    _fillRow(incomingIndex);
  }

  /// Só para teste: começa com a grade vazia, sem pilha nem linha de entrada
  /// sorteadas, para montar cenários determinísticos com [place].
  BlockGrid.empty({required this.columns, required this.rowCount}) {
    _allocateEmptyRows();
  }

  /// Só para teste: põe (ou remove, com `null`) um bloco numa célula, sem
  /// passar pelo sorteio de cor.
  void place(int index, int col, BlockColor? color) {
    _rows[index][col] = color == null ? null : Block(color);
  }

  final int columns;

  /// Linhas mantidas em memória: as visíveis mais a que está entrando por baixo.
  final int rowCount;

  /// Quantos iguais em sequência formam uma combinação.
  static const int matchLength = 3;

  /// Altura da pilha inicial, em linhas, sorteada por coluna.
  static const int minStartHeight = 3;
  static const int maxStartHeight = 6;

  /// A linha que está entrando por baixo, ainda fora da área visível. Ela é
  /// inerte: não combina nem cai, e serve de piso para a pilha.
  int get incomingIndex => rowCount - 1;

  /// Última linha jogável — a mais baixa que o jogador enxerga e manipula.
  int get floorIndex => rowCount - 2;

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
    _fillRow(incomingIndex);
  }

  /// Existe bloco no ar, ainda caindo.
  bool get hasFallingBlocks {
    for (var index = 0; index < incomingIndex; index++) {
      for (var col = 0; col < columns; col++) {
        if (_rows[index][col] != null && _rows[index + 1][col] == null) {
          return true;
        }
      }
    }
    return false;
  }

  /// Desce em uma linha todo bloco que não tem apoio. Bloco piscando ou
  /// estourando não cai.
  void applyGravityStep() {
    for (var index = floorIndex; index >= 0; index--) {
      for (var col = 0; col < columns; col++) {
        final block = _rows[index][col];
        if (block != null && block.isIdle && _rows[index + 1][col] == null) {
          _rows[index + 1][col] = block;
          _rows[index][col] = null;
          block.fallOffset += 1;
        }
      }
    }
  }

  void _allocateEmptyRows() {
    _rows
      ..clear()
      ..addAll(
        List.generate(rowCount , (_) => List<Block?>.filled(columns, null)),
      );
  }

  /// Pilha de abertura: cada coluna recebe uma altura sorteada, para o
  /// tabuleiro não começar com o topo reto.
  void _dealStartingStack() {
    final heights = List.generate(columns, (_) => _randomStartHeight());
    final tallest = heights.reduce(math.max);
    // Camada por camada, a partir do piso.
    for (var layer = 0; layer < tallest; layer++) {
      final index = floorIndex - layer;
      for (var col = 0; col < columns; col++) {
        if (layer < heights[col]) {
          _rows[index][col] = Block(_colorFor(index, col));
        }
      }
    }
  }

  int _randomStartHeight() =>
      minStartHeight + _random.nextInt(maxStartHeight - minStartHeight + 1);

  void _fillRow(int index) {
    for (var col = 0; col < columns; col++) {
      _rows[index][col] = Block(_colorFor(index, col));
    }
  }

  /// Sorteia uma cor que não feche uma combinação de saída. Sem isso o
  /// tabuleiro estouraria sozinho no primeiro frame, e cada linha nova
  /// entraria já estourando.
  BlockColor _colorFor(int index, int col) {
    final candidates = BlockColor.values
        .where((color) => !_wouldMatch(index, col, color))
        .toList();
    // Horizontal e vertical bloqueiam no máximo duas cores cada, então com
    // cinco cores sempre sobra alguma.
    assert(candidates.isNotEmpty, 'nenhuma cor livre em ($index, $col)');
    return candidates[_random.nextInt(candidates.length)];
  }

  bool _wouldMatch(int index, int col, BlockColor color) =>
      _runThrough(index, col, color, _horizontal) >= matchLength ||
      _runThrough(index, col, color, _vertical) >= matchLength;

  /// Tamanho da sequência de [color] que passaria por (index, col) na direção
  /// [step]. Soma os dois lados mais o próprio bloco que está sendo colocado —
  /// por isso independe da ordem em que a grade é preenchida. Checar um lado
  /// de cada vez deixaria passar o bloco colocado entre dois iguais.
  int _runThrough(int index, int col, BlockColor color, GridStep step) {
    final before = _sameRun(index, col, color, (
      index: -step.index,
      col: -step.col,
    ));
    final after = _sameRun(index, col, color, step);
    return before + 1 + after;
  }

  /// Quantos blocos da cor [color] existem em sequência a partir de
  /// (index, col), sem contar ele próprio, andando de [step] em [step].
  int _sameRun(int index, int col, BlockColor color, GridStep step) {
    var total = 0;
    var i = index + step.index;
    var c = col + step.col;
    while (i >= 0 && i < rowCount && c >= 0 && c < columns) {
      if (_rows[i][c]?.color != color) {
        break;
      }
      total++;
      i += step.index;
      c += step.col;
    }
    return total;
  }
}
