import 'dart:ui';

import 'package:flame/camera.dart';
import 'package:flame/components.dart' show Anchor;
import 'package:flame/game.dart';

import 'board_component.dart';
import 'gate_component.dart';
import 'hud_component.dart';
import 'layout.dart';
import 'score.dart';
import 'stack_raiser.dart';
import 'wall_component.dart';

class BlocosGame extends FlameGame {
  BlocosGame() : super(camera: _buildCamera());

  final stackRaiser = StackRaiser();
  final score = Score();

  late final BoardComponent board;
  late final WallComponent wall;

  /// Câmera de resolução fixa: o mundo é sempre visto como um canvas de
  /// [GameLayout.width]x[GameLayout.height], não importa o tamanho real do
  /// aparelho — a câmera escala/faz letterbox para caber. `topLeft` porque
  /// gate/board/wall são posicionados como num canvas de design comum
  /// (origem no canto superior esquerdo), não no centro (padrão do Flame).
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
    wall = WallComponent();
    await world.addAll([
      GateComponent(),
      board,
      wall,
      HudComponent(board: board, score: score),
    ]);

    // Gatilho temporário só para verificar visualmente que a wall se move:
    // a partida ainda não tem um fluxo de início real, então nada dispara
    // revealBoard() de verdade ainda. Remover quando existir esse fluxo.
    Future<void>.delayed(const Duration(seconds: 2), wall.revealBoard);
  }
}
