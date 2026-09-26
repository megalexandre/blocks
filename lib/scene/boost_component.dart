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

  /// Onde o botão fica, e **só** onde ele aceita toque.
  ///
  /// Era a faixa inteira da margem — 156 de largura, do topo ao pé do
  /// tabuleiro — com o argumento de ser um alvo fácil de acertar sem olhar.
  /// Na prática isso aceitava toque em muita coisa que não parece botão: a
  /// madeira do batente acima e abaixo do rebaixo, e a borda da tela. Botão
  /// que responde fora de onde aparece é botão que se aciona sem querer.
  ///
  /// Estático e função pura das constantes, pelo mesmo motivo do
  /// `BoardComponent.layoutFor()` e do `GateComponent.frameRect()`: é a mesma
  /// conta que desenha e que aceita o toque, e duas contas parecidas em
  /// lugares diferentes é como um botão passa a responder fora do lugar.
  static Rect targetRect(BoostSide side) {
    final board = BoardComponent.layoutFor();
    final borderStart = side == BoostSide.left
        ? board.position.x - UiScale.frameBorder
        : board.position.x + board.size.x;
    return Rect.fromLTWH(
      borderStart + (UiScale.frameBorder - _recessWidth) / 2,
      board.position.y + (board.size.y - _recessHeight) / 2,
      _recessWidth,
      _recessHeight,
    );
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    final target = targetRect(side);
    position = Vector2(target.left, target.top);
    this.size = Vector2(target.width, target.height);
  }

  /// A partida está correndo: a porta já abriu, a contagem já acabou e ninguém
  /// perdeu ainda.
  ///
  /// Lido do `risePaused`, que é o mesmo sinal que segura a pilha — e não de
  /// um estado próprio. Acelerar uma pilha que está parada não quer dizer
  /// nada, então o botão que acelera só existe quando ela anda.
  bool get _playing => !game.playfield.risePaused && !game.playfield.isOver;

  /// Fora da partida o toque **atravessa**, em vez de ser engolido por um
  /// botão que não faria nada. É o mesmo truque do `GameOverComponent` e da
  /// porta.
  @override
  bool containsLocalPoint(Vector2 point) =>
      _playing && super.containsLocalPoint(point);

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
    // A partida pode acabar — ou a porta fechar — com o dedo ainda em cima, e
    // o recomeço traz um jogo novo que não sabe que alguém está pressionando.
    if (!_playing) {
      _tapHeld = false;
      _dragHeld = false;
      return;
    }
    if (_pressed) {
      game.playfield.boosting = true;
    }
  }

  @override
  void render(Canvas canvas) {
    _painter.render(
      canvas,
      Rect.fromLTWH(0, 0, size.x, size.y),
      pressed: _pressed,
    );
  }
}

/// As duas faixas, uma de cada lado.
List<BoostComponent> boostBands() => [
  BoostComponent(BoostSide.left),
  BoostComponent(BoostSide.right),
];
