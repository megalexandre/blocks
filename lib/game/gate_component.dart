import 'package:flame/components.dart';

import 'layout.dart';

/// Fundo da tela inteira: a arte do gate, fixa, atrás de todo o resto.
/// Como o canvas do jogo é de resolução fixa ([GameLayout]), não precisa
/// reagir a resize — o próprio tamanho da tela é sempre o mesmo em pixels
/// do mundo, só a câmera escala isso para o aparelho real.
class GateComponent extends SpriteComponent {
  GateComponent() : super(size: GameLayout.size, position: Vector2.zero());

  @override
  Future<void> onLoad() async {
    sprite = await Sprite.load('gate_full_screen.png');
  }
}
