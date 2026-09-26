enum GameAsset {
  blocks('blocks/blocks.png'),
  selector('selector/selector.png'),
  scenario('scenario/background.png'),

  /// As quatro famílias de painel, empilhadas: cada uma é um bloco de 96×96
  /// com o nine-slice em 3×3 de 32. Gerada por `tool/build_ui_sheets.sh`.
  panels('ui/panels.png'),

  /// Fita de 36 glifos de 10×11: A–Z e depois 1–9 e 0, nessa ordem.
  bigText('ui/big_text.png'),

  /// Fita de 52 glifos de 5×6: A–Z, 1–9, 0, e então a pontuação.
  smallText('ui/small_text.png'),

  /// Fita de 25 ícones de 8×6.
  icons('ui/icons.png');

  const GameAsset(this.fileName);

  final String fileName;
}
