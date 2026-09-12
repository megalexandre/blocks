import 'dart:ui';

import 'package:flame/game.dart';

import '../ui/palette.dart';
import 'board_component.dart';
import 'stack_raiser.dart';

class BlocosGame extends FlameGame {
  final stackRaiser = StackRaiser();

  @override
  Color backgroundColor() => Palette.background;

  @override
  Future<void> onLoad() async {
    add(BoardComponent(stackRaiser: stackRaiser));
  }
}
