import 'dart:ui';

import 'package:flame/camera.dart';
import 'package:flame/components.dart' show Anchor;
import 'package:flame/game.dart';

import '../dressing/factory_elements.dart';
import 'board_component.dart';
import '../config/layout.dart';
import '../game/playfield.dart';

class GameScene extends FlameGame {
  /// Recebe o jogo pronto em vez de criá-lo: é o que deixa uma partida
  /// começar de um tabuleiro montado, em vez de sempre da pilha sorteada.
  /// Sem argumento, é a partida normal.
  GameScene({Playfield? playfield})
    : playfield = playfield ?? Playfield.standard(),
      super(camera: _buildCamera());

  /// O jogo. A cena o entrega ao tabuleiro; ninguém mais precisa saber que a
  /// pilha, o placar e a gravidade existem separados.
  final Playfield playfield;

  late final BoardComponent board;

  static CameraComponent _buildCamera() {
    final camera = CameraComponent.withFixedResolution(
      width: GameLayout.width,
      height: GameLayout.height,
    );
    camera.viewfinder.anchor = Anchor.topLeft;
    return camera;
  }

  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  Future<void> onLoad() async {
    final elements = await FactoryElements.load();
    board = BoardComponent(playfield: playfield, elements: elements);
    await world.add(board);
  }
}
