import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flutter/animation.dart' show Curves;

import '../config/layout.dart';
import '../dressing/panel_sprites.dart';
import 'game_scene.dart';
import 'gate_component.dart';

/// A porta que cobre o tabuleiro antes da partida.
///
/// Desce e sai de cena por baixo para revelar ([revealBoard]), e volta subindo
/// para cobrir ([hideBoard]). Só um objeto se move, então não tem o problema
/// geométrico de "buraco" que a troca de blocos tem.
///
/// **É maior que o vão** e corre **atrás** da moldura. Do tamanho exato do vão
/// e por cima da moldura, os entalhes transparentes dos cantos do painel
/// deixavam o tabuleiro vazar pelas quinas. Uma porta cobre o batente — mas só
/// o quanto `UiScale.doorOverlap` diz, senão ela tapa a madeira inteira.
///
/// A geometria vem das mesmas contas que o `BoardComponent` e o
/// `GateComponent` usam, e não de ler um deles: assim não depende da ordem de
/// montagem.
class WallComponent extends PositionComponent
    with TapCallbacks, HasGameReference<GameScene> {
  WallComponent({required this.onOpen}) : super(priority: 4);

  /// O que fazer quando o jogador toca na porta fechada.
  ///
  /// Callback, e não uma chamada à cena: a porta não precisa saber que existe
  /// uma partida do outro lado dela — precisa só avisar que foi tocada.
  final void Function() onOpen;

  /// Quanto dura o deslize. Herdado da parede antiga, que já tinha esse
  /// número escolhido no olho.
  static const double slideSeconds = 0.6;

  /// Família diferente da moldura de propósito: com a mesma nas duas, a porta
  /// fechada some dentro do batente e o conjunto vira uma tábua só.
  static const PanelFamily family = PanelFamily.yellowBoard;

  /// Fundo chapado atrás do nine-slice. O painel tem entalhe transparente nos
  /// cantos, e sem isto o tabuleiro aparece pelos furos do alfa.
  final _backdrop = Paint()..color = const Color(0xFF33323D);

  bool _covering = true;

  /// A porta está cobrindo o tabuleiro agora — parada em cima dele, não no
  /// meio de um deslize.
  bool get isCovering => _covering;

  Rect get _area => Rect.fromLTWH(0, 0, size.x, size.y);

  static Vector2 get _coveringPosition =>
      Vector2(GateComponent.doorRect().left, GateComponent.doorRect().top);

  static Vector2 get _hiddenPosition =>
      Vector2(GateComponent.doorRect().left, GameLayout.height);

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    // `this.size`, e não `size`: o parâmetro tem o mesmo nome e é o tamanho do
    // aparelho, não o da porta. Sem o `this` a atribuição some no parâmetro e
    // a porta fica com tamanho zero — invisível, e sem receber toque.
    final area = GateComponent.doorRect();
    this.size = Vector2(area.width, area.height);
    if (_covering) {
      position = _coveringPosition;
    }
  }

  /// Sobe e cobre o tabuleiro.
  void hideBoard({void Function()? onDone}) {
    _covering = true;
    add(MoveToEffect(
      _coveringPosition,
      EffectController(duration: slideSeconds, curve: Curves.easeOut),
      onComplete: onDone,
    ));
  }

  /// Desce, sai de cena e revela o tabuleiro.
  void revealBoard({void Function()? onDone}) {
    _covering = false;
    add(MoveToEffect(
      _hiddenPosition,
      EffectController(duration: slideSeconds, curve: Curves.easeIn),
      onComplete: onDone,
    ));
  }

  /// Volta para a posição de cobertura **sem animar**, para o recomeço abrir
  /// como a primeira partida abriu.
  void resetCovering() {
    _covering = true;
    removeWhere((c) => c is MoveToEffect);
    position = _coveringPosition;
  }

  /// Só recebe toque enquanto está cobrindo. Aberta, o toque atravessa para o
  /// tabuleiro — é o mesmo truque do `GameOverComponent`.
  @override
  bool containsLocalPoint(Vector2 point) =>
      _covering && super.containsLocalPoint(point);

  @override
  void onTapUp(TapUpEvent event) => onOpen();

  @override
  void render(Canvas canvas) {
    canvas.drawRect(_area, _backdrop);
    game.elements.panels.render(canvas, family, _area);
  }
}
