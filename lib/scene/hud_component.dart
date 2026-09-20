import 'dart:ui';

import 'package:flame/components.dart';

import '../config/layout.dart';
import '../dressing/hud_painter.dart';
import 'board_component.dart';
import 'game_scene.dart';

/// O placar, na faixa livre entre o topo da tela e o tabuleiro.
///
/// Lê o jogo **pela cena**, e não por uma referência guardada no construtor:
/// recomeçar troca o [Playfield] inteiro, e um placar que tivesse guardado o
/// antigo continuaria mostrando os pontos da partida perdida.
class HudComponent extends PositionComponent
    with HasGameReference<GameScene> {
  HudComponent() : super(priority: 10);

  final _painter = HudPainter();

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    // A faixa vai do topo da tela até onde o tabuleiro começa.
    final board = BoardComponent.layoutFor();
    position = Vector2.zero();
    this.size = Vector2(GameLayout.width, board.position.y);
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
