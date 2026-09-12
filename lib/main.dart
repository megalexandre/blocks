import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'game/blocos_game.dart';
import 'ui/controls_bar.dart';
import 'ui/palette.dart';

void main() {
  runApp(const BlocosApp());
}

class BlocosApp extends StatefulWidget {
  const BlocosApp({super.key});

  @override
  State<BlocosApp> createState() => _BlocosAppState();
}

class _BlocosAppState extends State<BlocosApp> {
  final _game = BlocosGame();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Blocos',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Palette.background,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(child: GameWidget(game: _game)),
              ControlsBar(game: _game),
            ],
          ),
        ),
      ),
    );
  }
}
