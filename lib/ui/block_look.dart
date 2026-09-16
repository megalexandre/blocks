import 'dart:ui';

import '../game/block.dart';

/// Como um [BlockColor] aparece na tela. Pura aparência — o [BlockColor] em
/// si não sabe nada disso.
class BlockLook {
  const BlockLook({required this.dark, required this.spriteColumn});

  /// Tom escuro da cor, usado hoje só no texto do indicador de chain no HUD.
  final Color dark;

  /// Coluna (0-5) do bloco dentro de `assets/images/blocks.png`, um sprite
  /// sheet de 6 tiles de 128×128: vermelho-coração, verde-círculo,
  /// ciano-gota (sem cor correspondente no jogo, não usado), azul-triângulo,
  /// amarelo-estrela, roxo-losango.
  final int spriteColumn;
}

const Map<BlockColor, BlockLook> blockLooks = {
  BlockColor.red: BlockLook(dark: Color(0xFFC97C88), spriteColumn: 0),
  BlockColor.blue: BlockLook(dark: Color(0xFF6E9BC0), spriteColumn: 3),
  BlockColor.green: BlockLook(dark: Color(0xFF6FAE8C), spriteColumn: 1),
  BlockColor.yellow: BlockLook(dark: Color(0xFFC7AD6A), spriteColumn: 4),
  BlockColor.purple: BlockLook(dark: Color(0xFF9C7EB8), spriteColumn: 5),
};

extension BlockColorLook on BlockColor {
  BlockLook get look => blockLooks[this]!;
}
