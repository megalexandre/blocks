enum GameAsset {
  gate('gate_full_screen.png'),
  wall('wall.png'),
  blocks('blocks/blocks.png'),
  selector('selector/selector.png');

  const GameAsset(this.fileName);

  final String fileName;
}
