import 'dart:ui';

import 'package:flame/camera.dart';
import 'package:flame/components.dart' show Anchor;
import 'package:flame/game.dart';

import '../dressing/factory_elements.dart';
import '../game/playfield.dart';
import '../config/layout.dart';
import 'board_component.dart';
import 'boost_component.dart';
import 'game_over_component.dart';
import 'hud_component.dart';

class GameScene extends FlameGame {
  /// Recebe uma **receita** de partida, não uma partida pronta.
  ///
  /// É o que permite recomeçar: perder e jogar de novo é montar outro
  /// [Playfield] do mesmo jeito que o primeiro, e só quem criou a cena sabe
  /// qual jeito é esse — a partida normal, ou um cenário do modo de
  /// desenvolvimento. Guardar o jogo pronto deixaria a cena sem como refazê-lo.
  GameScene({Playfield Function()? createPlayfield})
    : _createPlayfield = createPlayfield ?? Playfield.standard,
      super(camera: _buildCamera());

  final Playfield Function() _createPlayfield;

  /// O jogo desta partida. Troca inteiro a cada [restart].
  late Playfield playfield = _createPlayfield();

  late final FactoryElements elements;
  late BoardComponent board;

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
    elements = await FactoryElements.load();
    board = BoardComponent(playfield: playfield, elements: elements);
    await world.addAll([
      board,
      ...boostBands(),
      HudComponent(),
      GameOverComponent(),
    ]);
  }

  /// Joga fora a partida perdida e monta outra.
  ///
  /// O tabuleiro é recriado junto porque ele e o pintor recebem o jogo no
  /// construtor. O placar e o painel de fim de jogo não: eles perguntam à
  /// cena a cada quadro, e por isso atravessam o recomeço sem saber que
  /// houve um.
  Future<void> restart() async {
    playfield = _createPlayfield();
    board.removeFromParent();
    board = BoardComponent(playfield: playfield, elements: elements);
    await world.add(board);
  }
}
