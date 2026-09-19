enum BlockColor { red, blue, green, yellow, purple }

enum BlockState { idle, matched, popping }

class Block {
  Block(this.color);

  final BlockColor color;
  BlockState state = BlockState.idle;
  double stateTime = 0;
  double popDelay = 0;
  double fallOffset = 0;

  bool get isIdle => state == BlockState.idle;

  void enter(BlockState next) {
    state = next;
    stateTime = 0;
  }
}
