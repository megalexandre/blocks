import 'dart:ui';

enum BlockColor {
  red(Color(0xFFEF4D5E)),
  blue(Color(0xFF3F8EFC)),
  green(Color(0xFF3ECF8E)),
  yellow(Color(0xFFF5C542)),
  purple(Color(0xFFB26BF7));

  const BlockColor(this.color);

  final Color color;
}

enum BlockState {
  /// Parado na grade: pode ser trocado, cair e formar combinação.
  idle,

  /// Faz parte de uma combinação e está piscando, à espera de estourar.
  matched,

  /// Estourando. Ao fim é removido da grade.
  popping,
}

class Block {
  Block(this.color);

  final BlockColor color;

  BlockState state = BlockState.idle;

  /// Tempo acumulado dentro do estado atual.
  double stateTime = 0;

  /// Espera antes de estourar, para o grupo sair em cascata em vez de tudo
  /// de uma vez.
  double popDelay = 0;

  bool get isIdle => state == BlockState.idle;

  void enter(BlockState next) {
    state = next;
    stateTime = 0;
  }
}
