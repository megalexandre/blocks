import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'scene/game_scene.dart';
import 'dressing/palette.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const BlocosApp());
}

class BlocosApp extends StatefulWidget {
  const BlocosApp({super.key});

  @override
  State<BlocosApp> createState() => _BlocosAppState();
}

class _BlocosAppState extends State<BlocosApp> {
  final _game = GameScene();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Blocos',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Palette.background,
        body: GameWidget(game: _game),
      ),
    );
  }
}
