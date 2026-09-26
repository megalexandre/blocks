import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../config/layout.dart';
import '../dressing/palette.dart';
import '../dressing/panel_sprites.dart';
import '../dressing/ui_scale.dart';
import 'game_scene.dart';

/// A tela de carregamento.
///
/// Dona do carregamento pesado. O `GameWidget.loadingBuilder` do Flutter só
/// cobre o intervalo em que o `onLoad` da cena roda, e lá dentro só entram as
/// folhas de interface — poucos quilobytes. O que se vê é esta tela.
///
/// **Tem um tempo mínimo em cena.** Hoje os assets somam uns 250 KB e carregam
/// num piscar; sem um piso, a tela apareceria e sumiria no mesmo quadro, e o
/// que o jogador veria seria um tremor, não um carregamento. O piso também
/// cobre a segunda entrada, em que o cache de imagens do Flame devolve tudo
/// instantaneamente.
class LoadingPage extends PositionComponent with HasGameReference<GameScene> {
  static const double _minimumSeconds = 0.7;

  double _elapsed = 0;
  double _progress = 0;
  bool _loaded = false;
  bool _left = false;

  @override
  Future<void> onLoad() async {
    await game.elements.loadGame(
      onProgress: (done, total) => _progress = done / total,
    );
    _loaded = true;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    if (_left || !_loaded || _elapsed < _minimumSeconds) {
      return;
    }
    _left = true;
    game.router.pushReplacementNamed(game.afterLoading);
  }

  @override
  void render(Canvas canvas) {
    final faixa = Rect.fromLTWH(140, 700, 800, 300);
    game.elements.panels.render(canvas, PanelFamily.yellowBoard, faixa);
    game.elements.headline.renderCentered(
      canvas,
      'BLOCOS',
      faixa,
      scale: UiScale.title,
    );

    final trilho = Rect.fromLTWH(200, 1240, 680, 56);
    canvas
      ..drawRect(trilho, Paint()..color = Palette.insetShadow)
      ..drawRect(
        Rect.fromLTWH(
          trilho.left,
          trilho.top,
          // Nunca anda para trás e nunca some: a barra cheia de menos que um
          // pixel some, e uma barra que some parece travada.
          math.max(4, trilho.width * _progress),
          trilho.height,
        ),
        Paint()..color = Palette.textPrimary,
      );

    game.elements.label.renderCentered(
      canvas,
      'CARREGANDO',
      Rect.fromLTWH(0, 1340, GameLayout.width, 40),
      scale: UiScale.label,
      tint: Palette.textSecondary,
    );
  }
}
