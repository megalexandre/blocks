import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'scene/game_scene.dart';
import 'dressing/game_sounds.dart';
import 'dressing/palette.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  // Antes de montar a tela: o motor de áudio leva um tempo para subir, e
  // o primeiro impacto acontece poucos décimos depois de a partida abrir.
  GameSounds.warmUp();
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
        body: GameWidget(
          game: _game,
          // O Flame desenha um quadro vazio enquanto o `onLoad` da cena roda.
          // Sem isto ele sai chapado, e o primeiro quadro do jogo é um
          // retângulo sem nada.
          loadingBuilder: (_) => const ColoredBox(color: Palette.background),
        ),
      ),
    );
  }
}
