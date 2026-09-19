import 'package:flame/game.dart';

class GameLayout {
  GameLayout._();

  static const double width = 1080;
  static const double height = 1920;

  static Vector2 get size => Vector2(width, height);

  static const double boardVoidLeft = 156;
  static const double boardVoidTop = 256;
  static const double boardVoidWidth = 768;
}
