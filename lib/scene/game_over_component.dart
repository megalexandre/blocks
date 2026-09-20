import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';

import '../dressing/game_over_painter.dart';
import 'board_component.dart';
import 'game_scene.dart';

/// O painel de fim de partida, por cima do tabuleiro.
///
/// Ocupa a mesma área do tabuleiro e só aparece quando a partida acabou —
/// durante o jogo ele não desenha nem aceita toque, então não atrapalha o
/// arraste que troca os blocos.
class GameOverComponent extends PositionComponent
    with TapCallbacks, HasGameReference<GameScene> {
  GameOverComponent() : super(priority: 20);

  final _painter = GameOverPainter();

  bool get _isOver => game.playfield.isOver;

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    final board = BoardComponent.layoutFor();
    position = board.position;
    this.size = board.size;
  }

  /// Enquanto a partida corre, o toque atravessa: quem recebe é o tabuleiro,
  /// que fica embaixo. Sem isto o painel roubaria todo arraste do jogo.
  @override
  bool containsLocalPoint(Vector2 point) =>
      _isOver && super.containsLocalPoint(point);

  @override
  void onTapUp(TapUpEvent event) {
    final local = Offset(event.localPosition.x, event.localPosition.y);
    if (GameOverPainter.buttonRect(Offset.zero & Size(size.x, size.y))
        .contains(local)) {
      game.restart();
    }
  }

  @override
  void render(Canvas canvas) {
    if (!_isOver) {
      return;
    }
    _painter.render(
      canvas,
      Offset.zero & Size(size.x, size.y),
      score: game.playfield.score.total,
    );
  }
}
