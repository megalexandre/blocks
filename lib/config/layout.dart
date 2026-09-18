import 'package:flame/game.dart';

/// Canvas de referência do jogo: gate, board, wall e HUD são todos
/// posicionados neste espaço fixo de pixels. A câmera do [GameScene] usa
/// resolução fixa nesse tamanho (ver [CameraComponent.withFixedResolution]
/// em `game_scene.dart`), então esses pixels são os mesmos em qualquer
/// aparelho — é isso que garante o gate alinhado.
///
/// O tamanho bate com o nativo de `gate_full_screen.svg`/`.png`
/// (1078×1918, <0,2% de diferença): o design já nasceu nessa escala.
class GameLayout {
  GameLayout._();

  static const double width = 1080;
  static const double height = 1920;

  static Vector2 get size => Vector2(width, height);

  /// Abertura interna da moldura do gate (o "vão da porta"), onde o board
  /// deve aparecer — medida direto em `gate_full_screen.png` (renderizado
  /// com `rsvg-convert`, que respeita os `clipPath` do SVG; o `flutter_svg`
  /// não respeitava e produzia uma imagem toda errada). A moldura mede
  /// 64px de espessura nas quatro bordas; a abertura interna é exatamente
  /// 768×1536 — o mesmo tamanho nativo de `wall.png` — e 768/6 colunas =
  /// 128px por célula, 128×12 linhas = 1536: bate exato com um board de
  /// 6×12. Não é coincidência, a arte foi desenhada pra esse board.
  static const double boardVoidLeft = 156;
  static const double boardVoidTop = 256;
  static const double boardVoidWidth = 768;
}
