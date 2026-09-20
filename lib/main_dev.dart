import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'debug/debug_menu_page.dart';
import 'dressing/game_sounds.dart';
import 'dressing/palette.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp]);
  // Antes de montar a tela: o motor de áudio leva um tempo para subir, e
  // o primeiro impacto acontece poucos décimos depois de a partida abrir.
  GameSounds.warmUp();
  runApp(const BlocosDevApp());
}

class BlocosDevApp extends StatelessWidget {
  const BlocosDevApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Blocos (dev)',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Palette.background,
        useMaterial3: true,
      ),
      home: const DebugMenuPage(),
    );
  }
}
