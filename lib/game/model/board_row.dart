import 'block.dart';
import 'column.dart';

/// Uma linha do tabuleiro: as células, e a identidade da linha.
///
/// Guardar uma [BoardRow] é o jeito de apontar para uma linha através do
/// tempo. A pilha subir não mexe nisso — é o mesmo objeto antes e depois,
/// então não existe número para corrigir nem índice que "envelhece". Quando a
/// linha sai pelo topo, a grade simplesmente para de tê-la, e
/// `BlockGrid.positionOf` passa a responder nulo.
///
/// A posição **visual** (0 = topo da tela) é outra coisa, e é de quem desenha:
/// pergunte para a grade no frame em que for usar, nunca guarde.
class BoardRow {
  BoardRow.empty(int columnCount)
    : cells = List<Block?>.filled(columnCount, null);

  /// Por coluna, da esquerda para a direita. Nulo é célula vazia.
  final List<Block?> cells;

  Block? operator [](Column col) => cells[col.value];

  void operator []=(Column col, Block? block) {
    cells[col.value] = block;
  }

  /// Nenhuma célula ocupada. A linha que sai pelo topo precisa estar assim,
  /// ou o jogador perdeu.
  bool get isEmpty => cells.every((cell) => cell == null);

  /// Troca dois blocos de lugar dentro da linha.
  void swapCells(Column a, Column b) {
    final held = cells[a.value];
    cells[a.value] = cells[b.value];
    cells[b.value] = held;
  }

  /// Célula vazia pode receber bloco; bloco só sai se estiver **assentado**.
  ///
  /// Assentado, e não só parado: um bloco no meio do rastro de queda ainda é
  /// `isIdle`, e trocá-lo ali fazia o rastro continuar rodando na coluna
  /// nova, como se o bloco tivesse caído de um lugar onde nunca esteve.
  bool isSwappable(Column col) => cells[col.value]?.isSettled ?? true;
}
