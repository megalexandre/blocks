import 'package:flame/game.dart';

class GameLayout {
  GameLayout._();

  static const double width = 1080;
  static const double height = 1920;

  static Vector2 get size => Vector2(width, height);

  static const double boardVoidLeft = 156;
  static const double boardVoidTop = 256;
  static const double boardVoidWidth = 768;

  /// Altura do vão. Até agora só existia implícita — 768 ÷ 6 colunas dá uma
  /// célula de 128, e 12 linhas dão 1536 —, e passou a ser constante quando
  /// a arte do cenário precisou de um recorte para desenhar dentro do vão.
  static const double boardVoidHeight = 1536;
}
