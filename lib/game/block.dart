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
