import 'dart:ui';

import 'package:flame/camera.dart';
import 'package:flame/components.dart' show Anchor;
import 'package:flame/game.dart';

import 'board_component.dart';
import 'layout.dart';
import 'score.dart';
import 'stack_raiser.dart';

class BlocosGame extends FlameGame {
  BlocosGame() : super(camera: _buildCamera());

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
    board = BoardComponent(stackRaiser: stackRaiser, score: score);
    await world.add(board);
  }
}
