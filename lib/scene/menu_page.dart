import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';

import '../dressing/panel_sprites.dart';
import '../dressing/ui_scale.dart';
import 'game_scene.dart';
import 'routes.dart';

/// O menu.
///
/// Rota do Flame, e não página Flutter: as duas fontes do jogo são folhas de
/// sprite, e num widget elas precisariam de um pintor próprio só para
/// aparecer. Aqui elas são desenhadas pelo mesmo `BitmapText` que o placar usa,
/// e tudo escala junto com o canvas fixo.
class MenuPage extends PositionComponent with HasGameReference<GameScene> {
  /// A faixa do título e os botões abaixo.
  static final Rect banner = Rect.fromLTWH(140, 170, 800, 300);

  /// Os botões **não** usam a família da faixa. Vestindo os dois igual, o
  /// título e as ações viram um bloco só, e a hierarquia some.
  static const PanelFamily bannerFamily = PanelFamily.yellowBoard;
  static const PanelFamily buttonFamily = PanelFamily.yellowPaper;

  static const List<(String, String)> _items = [
    ('JOGAR', Routes.match),
  ];

  static Rect buttonRect(int index) =>
      Rect.fromLTWH(250, 700 + index * 310, 580, 210);

  @override
  Future<void> onLoad() async {
    for (var i = 0; i < _items.length; i++) {
      await add(_MenuButton(index: i, label: _items[i].$1, route: _items[i].$2));
    }
  }

  @override
  void render(Canvas canvas) {
    game.elements.panels.render(canvas, bannerFamily, banner);
    game.elements.headline.renderCentered(
      canvas,
      'BLOCOS',
      banner,
      scale: UiScale.title,
    );
  }
}

/// Um item do menu. Componente próprio porque ele precisa receber toque, e
/// toque no Flame é do componente, não do desenho.
class _MenuButton extends PositionComponent
    with TapCallbacks, HasGameReference<GameScene> {
  _MenuButton({required this.index, required this.label, required this.route});

  final int index;
  final String label;
  final String route;

  bool _pressed = false;

  @override
  Future<void> onLoad() async {
    final rect = MenuPage.buttonRect(index);
    position = Vector2(rect.left, rect.top);
    size = Vector2(rect.width, rect.height);
  }

  @override
  void onTapDown(TapDownEvent event) => _pressed = true;

  @override
  void onTapCancel(TapCancelEvent event) => _pressed = false;

  @override
  void onTapUp(TapUpEvent event) {
    _pressed = false;
    game.router.pushReplacementNamed(route);
  }

  @override
  void render(Canvas canvas) {
    // Afundar alguns pixels ao ser pressionado é a convenção do pacote, e
    // custa menos que uma segunda família de painel só para o estado apertado.
    final offset = _pressed ? 6.0 : 0.0;
    final area = Rect.fromLTWH(0, offset, size.x, size.y - offset);
    game.elements.panels.render(
      canvas,
      MenuPage.buttonFamily,
      area,
      scale: UiScale.button,
    );
    game.elements.headline.renderCentered(
      canvas,
      label,
      area,
      scale: UiScale.headline,
    );
  }
}
