import 'dart:ui';

import '../game/block.dart';

class BlockLook {
  const BlockLook({required this.dark});
  final Color dark;
}

const Map<BlockColor, BlockLook> blockLooks = {
  BlockColor.red: BlockLook(dark: Color(0xFFC97C88)),
  BlockColor.blue: BlockLook(dark: Color(0xFF6E9BC0)),
  BlockColor.green: BlockLook(dark: Color(0xFF6FAE8C)),
  BlockColor.yellow: BlockLook(dark: Color(0xFFC7AD6A)),
  BlockColor.purple: BlockLook(dark: Color(0xFF9C7EB8)),
};

extension BlockColorLook on BlockColor {
  BlockLook get look => blockLooks[this]!;
}
