enum BlockColor { red, blue, green, yellow, purple }

enum BlockState { idle, matched, popping }

class Block {
  Block(this.color);

  final BlockColor color;
  BlockState state = BlockState.idle;
  double stateTime = 0;

  /// Quando **este** bloco começa a encolher, contado do início do estouro.
  /// É o que escalona a cascata da esquerda para a direita.
  double popDelay = 0;

  /// Quando ele sai da grade, contado do mesmo início.
  ///
  /// Vale para o **grupo inteiro**, não para este bloco: todos os blocos de
  /// uma combinação somem no mesmo instante, quando o último terminou de
  /// encolher. Removendo cada um no fim do próprio estouro, a célula da
  /// esquerda ficava livre um passo da cascata antes da célula à direita, e a
  /// pilha de cima desabava em escada em vez de cair inteira.
  ///
  /// Mora no bloco, e não numa lista de células guardada por quem estoura:
  /// uma lista de posições envelheceria na primeira subida da pilha, enquanto
  /// o bloco leva o próprio prazo junto aonde quer que a grade o mande.
  double clearAt = 0;

  double fallOffset = 0;

  bool get isIdle => state == BlockState.idle;

  /// Parado **e no lugar**. [isIdle] sozinho diz só que o bloco não está
  /// piscando nem estourando — um bloco em pleno rastro de queda é `isIdle`,
  /// e era por isso que dava para trocá-lo no ar.
  bool get isSettled => isIdle && fallOffset == 0;

  void enter(BlockState next) {
    state = next;
    stateTime = 0;
  }
}
