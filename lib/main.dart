import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'scene/game_scene.dart';
import 'dressing/palette.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp]);
  // Tela cheia de verdade: esconde barra de status e de navegação. Sticky
  // porque o jogo é todo arrastar o dedo na tela — em `leanBack` qualquer
  // toque traria as barras de volta. Aqui elas só reaparecem se o jogador
  // deslizar da borda, e somem sozinhas.
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
        // Sem SafeArea de propósito: a câmera de resolução fixa já faz
        // letterbox para caber em qualquer proporção, então o fundo pode
        // ocupar a tela inteira, entalhe incluído.
        body: GameWidget(game: _game),
      ),
    );
  }
}
