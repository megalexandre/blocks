import 'dart:ui';

import 'package:flame/components.dart';

import '../config/layout.dart';
import '../dressing/hud_painter.dart';
import 'gate_component.dart';
import 'game_scene.dart';

/// O placar, na faixa livre entre o topo da tela e o tabuleiro.
///
/// Lê o jogo **pela cena**, e não por uma referência guardada no construtor:
/// recomeçar troca o [Playfield] inteiro, e um placar que tivesse guardado o
/// antigo continuaria mostrando os pontos da partida perdida.
class HudComponent extends PositionComponent
    with HasGameReference<GameScene> {
  HudComponent() : super(priority: 10);

  late final _painter = HudPainter(game.elements);

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    // Até onde a **moldura** começa, e não o tabuleiro: entre os dois há a
    // borda do batente, e o placar desenhado ali ficava por baixo da madeira.
    position = Vector2.zero();
    this.size = Vector2(GameLayout.width, GateComponent.frameRect().top);
  }

  @override
  void render(Canvas canvas) {
    final playfield = game.playfield;
    _painter.render(
      canvas,
      Offset.zero & Size(size.x, size.y),
      score: playfield.score.total,
      chainLevel: playfield.chainLevel,
    );
  }
}
