enum GameAsset {
  blocks('blocks/blocks.png'),
  selector('selector/selector.png'),
  scenario('scenario/background.png');

  const GameAsset(this.fileName);

  final String fileName;
}
