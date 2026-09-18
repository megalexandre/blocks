import 'dart:ui';

import 'package:flame/camera.dart';
import 'package:flame/components.dart' show Anchor;
import 'package:flame/game.dart';

import '../dressing/factory_elements.dart';
import 'board_component.dart';
import '../config/layout.dart';
import '../game/score.dart';
import '../game/stack_raiser.dart';

class GameScene extends FlameGame {
  GameScene() : super(camera: _buildCamera());

  final stackRaiser = StackRaiser();
  final score = Score();

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
    board = BoardComponent(
      stackRaiser: stackRaiser,
      score: score,
      elements: elements,
    );
    await world.add(board);
  }
}
