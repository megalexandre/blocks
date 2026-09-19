import 'column.dart';
import 'row_index.dart';

/// As medidas do tabuleiro **em células**: quantas colunas, quantas linhas, e
/// qual linha é o quê.
///
/// Value object imutável, criado uma vez — o equivalente em células do que o
/// `BoardViewport` é em pixels. Os dois não se fundem de propósito: um é de
/// quem desenha e sabe pixel, o outro é do jogo e não pode saber.
///
/// Guarda as listas de [RowIndex] e [Column] **já prontas** porque elas são
/// percorridas várias vezes por quadro, e uma `List<RowIndex>` *é* uma
/// `List<int>` em tempo de execução: o laço duplo ganha nome no lugar de
/// `for (var i = 0; i < n; i++)` sem custar uma alocação.
class BoardGeometry {
  BoardGeometry({required this.columnCount, required this.visibleRowCount})
    : rowCount = visibleRowCount + 1,
      columns = List.generate(columnCount, Column.new, growable: false),
      allRows = List.generate(
        visibleRowCount + 1,
        RowIndex.new,
        growable: false,
      ),
      playableRows = List.generate(
        visibleRowCount,
        RowIndex.new,
        growable: false,
      ),
      rowsBottomUp = List.generate(
        visibleRowCount,
        (i) => RowIndex(visibleRowCount - 1 - i),
        growable: false,
      );

  /// Seis colunas por doze linhas visíveis: o tabuleiro para o qual a arte do
  /// gate foi desenhada (ver `GameLayout.boardVoidWidth`).
  static final BoardGeometry standard = BoardGeometry(
    columnCount: 6,
    visibleRowCount: 12,
  );

  final int columnCount;

  /// Quantas linhas o jogador enxerga e manipula.
  final int visibleRowCount;

  /// As visíveis mais a que está entrando por baixo.
  final int rowCount;

  final List<Column> columns;

  /// Todas, inclusive a que está entrando. Para quem desenha.
  final List<RowIndex> allRows;

  /// Só as jogáveis, do topo para o piso. Para quem procura combinação.
  final List<RowIndex> playableRows;

  /// Só as jogáveis, **do piso para o topo**. Para a gravidade: descer
  /// primeiro quem está mais embaixo é o que faz uma coluna inteira cair num
  /// passo só, em vez de uma linha por passo.
  final List<RowIndex> rowsBottomUp;

  /// A linha que está prestes a sair pelo topo.
  RowIndex get topRow => const RowIndex(0);

  /// Última linha jogável — a mais baixa que o jogador enxerga e manipula.
  RowIndex get floorRow => RowIndex(rowCount - 2);

  /// A linha que está entrando por baixo, ainda fora da área visível. Ela é
  /// inerte: não combina nem cai, e serve de piso para a pilha.
  RowIndex get incomingRow => RowIndex(rowCount - 1);

  bool holds(RowIndex row, Column col) =>
      row.value >= 0 &&
      row.value < rowCount &&
      col.value >= 0 &&
      col.value < columnCount;

  /// A única porta de entrada de um `int` cru virando coordenada: o toque do
  /// jogador, que chega em pixel e vira célula.
  Column clampColumn(int raw) => Column(raw.clamp(0, columnCount - 1));

  /// Idem, mas nunca devolve a linha que está entrando — ela ainda não está
  /// em jogo.
  RowIndex clampPlayableRow(int raw) => RowIndex(raw.clamp(0, floorRow.value));
}
