import 'column.dart';
import 'row_index.dart';

/// Um par linha/coluna que precisa **viajar**: o conjunto de células
/// combinadas, um evento, o toque do jogador.
///
/// Record e não extension type, embora o resto do vocabulário de coordenadas
/// seja. Um extension type sobre um record continuaria alocando o record, e
/// as varreduras quentes visitam a grade inteira várias vezes por quadro —
/// elas recebem [RowIndex] e [Column] como **dois parâmetros**, que os tipos
/// já impedem de inverter, sem alocar nada. A [Cell] só aparece onde o par
/// precisa andar junto.
typedef Cell = ({RowIndex row, Column col});

/// Esquerda para a direita, de baixo para cima: a ordem em que a cascata do
/// estouro sai.
///
/// Mora aqui, com a célula, e não com quem estoura: é a ordem **das
/// posições**, e o estouro só a consome para escalonar o atraso de cada
/// bloco.
int cascadeOrder(Cell a, Cell b) {
  final byColumn = a.col.compareTo(b.col);
  return byColumn != 0 ? byColumn : b.row.compareTo(a.row);
}
