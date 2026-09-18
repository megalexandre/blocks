import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/animation.dart' show Curves;

import '../scene/board_component.dart';
import '../dressing/game_assets.dart';
import '../config/layout.dart';

/// Cobre o board para esconder os blocos antes da partida. Desliza para
/// cima vindo de baixo da tela para cobrir ([hideBoard]), e desliza de
/// volta para baixo, saindo de cena, para revelar ([revealBoard]) — só um
/// objeto se move, então não tem o problema geométrico de "buraco" que a
/// troca de blocos tem (ver decisões de animação do board).
///
/// A posição/tamanho de cobertura é calculada a partir das mesmas
/// constantes que [BoardComponent] usa para se posicionar
/// ([BoardComponent.layoutFor]), não lendo o board em si — assim não
/// depende da ordem de montagem dos dois componentes.
class WallComponent extends SpriteComponent {
  static const double _slideSeconds = 0.6;

  @override
  Future<void> onLoad() async {
    sprite = await Sprite.load(GameAsset.wall.fileName);
    final layout = BoardComponent.layoutFor();
    size = layout.size;
    position = _coveringPosition(layout.position);
  }

  Vector2 _coveringPosition(Vector2 boardPosition) => boardPosition.clone();

  Vector2 _hiddenPosition(Vector2 boardPosition) =>
      Vector2(boardPosition.x, GameLayout.height);

  /// Desliza a wall para cima, cobrindo o board.
  void hideBoard() {
    final layout = BoardComponent.layoutFor();
    add(
      MoveToEffect(
        _coveringPosition(layout.position),
        EffectController(duration: _slideSeconds, curve: Curves.easeOut),
      ),
    );
  }

  /// Desliza a wall de volta para baixo, saindo de cena e revelando o board.
  void revealBoard() {
    final layout = BoardComponent.layoutFor();
    add(
      MoveToEffect(
        _hiddenPosition(layout.position),
        EffectController(duration: _slideSeconds, curve: Curves.easeIn),
      ),
    );
  }
}
