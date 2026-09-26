import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';

import '../dressing/boost_painter.dart';
import '../dressing/ui_scale.dart';
import 'board_component.dart';
import 'game_scene.dart';

/// De que lado da tela a faixa fica.
enum BoostSide { left, right }

/// A faixa que acelera a subida da pilha enquanto está pressionada.
///
/// Fica **fora** do tabuleiro, numa das margens. Dentro dele o toque já tem
/// dono: é o arraste que troca dois blocos, e um botão ali disputaria o mesmo
/// gesto. São duas faixas, uma de cada lado, para servir canhoto e destro sem
/// obrigar ninguém a trocar a mão de lugar no meio da partida.
///
/// Trata toque **e** arraste. Manter o dedo parado não existe na prática: ele
/// escorrega alguns pixels, e só com o toque a pressão seria cancelada no
/// meio — a pilha voltaria à velocidade normal sozinha, sem o jogador ter
/// soltado nada.
class BoostComponent extends PositionComponent
    with TapCallbacks, DragCallbacks, HasGameReference<GameScene> {
  BoostComponent(this.side) : super(priority: 10);

  final BoostSide side;

  /// Medidas do rebaixo cavado na lateral da moldura. Mais estreito que o
  /// batente de 128, para sobrar madeira dos dois lados dele.
  static const double _recessWidth = 96;
  static const double _recessHeight = 520;

  late final _painter = BoostPainter(game.elements);

  /// Toque e arraste são contados **separados**.
  ///
  /// Ao encostar o dedo, o Flame dispara o toque e, quando o arraste assume,
  /// cancela o toque — nessa ordem. Com um único sinalizador, o cancelamento
  /// do toque desligava o impulso que o arraste tinha acabado de ligar, e a
  /// pilha voltava à velocidade normal com o dedo ainda na tela.
  bool _tapHeld = false;
  bool _dragHeld = false;

  bool get _pressed => _tapHeld || _dragHeld;

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    final board = BoardComponent.layoutFor();
    final width = board.position.x;
    position = Vector2(
      side == BoostSide.left ? 0 : board.position.x + board.size.x,
      board.position.y,
    );
    this.size = Vector2(width, board.size.y);
  }

  void _apply() => game.playfield.boosting = _pressed;

  @override
  void onTapDown(TapDownEvent event) {
    _tapHeld = true;
    _apply();
  }

  @override
  void onTapUp(TapUpEvent event) {
    _tapHeld = false;
    _apply();
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    _tapHeld = false;
    _apply();
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    _dragHeld = true;
    _apply();
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    _dragHeld = false;
    _apply();
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);
    _dragHeld = false;
    _apply();
  }

  @override
  void update(double dt) {
    super.update(dt);
    // A partida pode ter acabado com o dedo ainda em cima, e o recomeço traz
    // um jogo novo que não sabe que alguém está pressionando.
    if (_pressed && !game.playfield.isOver) {
      game.playfield.boosting = true;
    }
  }

  /// Onde o rebaixo é desenhado, em coordenadas locais da faixa.
  ///
  /// A faixa tem a largura da margem (156) e o batente da moldura ocupa os
  /// 128 encostados no tabuleiro — à direita na faixa da esquerda, à esquerda
  /// na da direita. O rebaixo é centrado nesse batente, e não na faixa: ele
  /// pertence à moldura, e a faixa é só quem recebe o toque.
  Rect _recess() {
    final borderStart =
        side == BoostSide.left ? size.x - UiScale.frameBorder : 0.0;
    return Rect.fromLTWH(
      borderStart + (UiScale.frameBorder - _recessWidth) / 2,
      (size.y - _recessHeight) / 2,
      _recessWidth,
      _recessHeight,
    );
  }

  @override
  void render(Canvas canvas) {
    _painter.render(canvas, _recess(), pressed: _pressed);
  }
}

/// As duas faixas, uma de cada lado.
List<BoostComponent> boostBands() => [
  BoostComponent(BoostSide.left),
  BoostComponent(BoostSide.right),
];
