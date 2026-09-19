import 'block.dart';
import 'board_geometry.dart';
import 'board_row.dart';
import 'cell.dart';
import 'column.dart';
import 'row_index.dart';

/// Quem está em cada célula. Só isso.
///
/// Perdeu dois papéis que acumulava: **fábrica** — a pilha de abertura e o
/// sorteio foram para `StackFiller` — e **motor de física** — a queda e o
/// rastro foram para `GravitySystem`. O que sobrou não tem `dt` em assinatura
/// nenhuma, e é isso que faz dela estado em vez de sistema.
///
/// Só existe uma coordenada de linha aqui: a **posição visual**, 0 no topo
/// da tela. Ela muda de significado a cada [shiftUp], então nunca deve ser
/// guardada entre frames — quem precisa apontar para uma linha ao longo do
/// tempo guarda a [BoardRow] e pergunta a posição com [positionOf] na hora de
/// usar.
class BlockGrid {
  /// Nasce **vazia, sempre**.
  ///
  /// Antes o construtor sorteava a pilha de abertura e a linha de entrada, e
  /// era por isso que existiam um `BlockGrid.empty` e um `place` marcados "só
  /// para teste": não havia como montar um cenário previsível sem uma porta
  /// dos fundos. Com quem enche a grade separado (`StackFiller`), a porta dos
  /// fundos virou a porta da frente — [put] é a mesma API para o jogo e para
  /// o teste.
  BlockGrid(this.geometry)
    : _rows = List.generate(
        geometry.rowCount,
        (_) => BoardRow.empty(geometry.columnCount),
        growable: true,
      );

  final BoardGeometry geometry;

  /// Ordem visual: índice 0 é o topo, o último é a linha que está entrando.
  final List<BoardRow> _rows;

  /// A linha que está na posição visual [row].
  BoardRow rowAt(RowIndex row) => _rows[row.value];

  /// Posição visual de [row] agora, ou nulo se ela já saiu pelo topo.
  ///
  /// Varredura linear, mas são 13 linhas: quem chama está desenhando um
  /// frame, não percorrendo um índice grande.
  RowIndex? positionOf(BoardRow row) {
    final found = _rows.indexOf(row);
    return found < 0 ? null : RowIndex(found);
  }

  /// A linha ainda está no tabuleiro.
  bool contains(BoardRow row) => _rows.contains(row);

  /// O bloco em (row, col), ou nulo — inclusive **fora dos limites**.
  ///
  /// Tolerante de propósito: quem procura uma sequência de mesma cor anda até
  /// achar diferente, e devolver nulo na borda faz o laço parar sozinho em
  /// vez de repetir uma comparação de contorno a cada passo. A escrita é o
  /// contrário: [put] é estrita, para um erro de coordenada estourar na hora
  /// em que acontece em vez de sumir.
  Block? blockAt(RowIndex row, Column col) =>
      geometry.holds(row, col) ? _rows[row.value][col] : null;

  void put(RowIndex row, Column col, Block? block) {
    assert(geometry.holds(row, col), 'célula fora do tabuleiro');
    _rows[row.value][col] = block;
  }

  void clear(RowIndex row, Column col) => put(row, col, null);

  void move({required Cell from, required Cell to}) {
    put(to.row, to.col, blockAt(from.row, from.col));
    clear(from.row, from.col);
  }

  /// Troca dois blocos de lugar dentro de uma linha.
  ///
  /// **Passa por aqui, e não pela [BoardRow] direto**: a troca mexia na linha
  /// sem a grade saber, o que contradizia a regra — escrita no próprio
  /// código — de que a grade é dona exclusiva do próprio estado. Dart não tem
  /// como proibir isso no compilador; o que dá para fazer é a troca ter uma
  /// porta só, e ela ser esta.
  void swap(BoardRow row, Column a, Column b) => row.swapCells(a, b);

  /// Os dois lados podem ser trocados agora: célula vazia pode, bloco só se
  /// estiver assentado.
  bool canSwap(BoardRow row, Column a, Column b) =>
      row.isSwappable(a) && row.isSwappable(b);

  /// A linha do topo sai do tabuleiro, uma vazia entra por baixo. Quem
  /// guardou uma [BoardRow] continua apontando para a mesma linha — só a
  /// posição visual dela mudou.
  ///
  /// Devolve a linha que saiu, e **não** enche a que entrou: encher é do
  /// `StackFiller`, e quem saiu interessa a quem precisa saber se ela levava
  /// bloco junto — sair do topo com bloco é o fim da partida.
  BoardRow shiftUp() {
    final leaving = _rows.removeAt(0);
    _rows.add(BoardRow.empty(geometry.columnCount));
    return leaving;
  }
}
