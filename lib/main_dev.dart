import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'debug/debug_menu_page.dart';
import 'dressing/palette.dart';

/// Ponto de entrada do **modo de desenvolvimento**: abre num menu de
/// cenários em vez de cair direto numa partida.
///
/// Entry point separado, e não um `if (kDebugMode)` dentro do `main.dart`:
/// assim a pasta `debug/` não entra no grafo de imports do jogo publicado, e
/// o `main.dart` fica exatamente como estava.
///
/// Para rodar: `flutter run -t lib/main_dev.dart` (ou a configuração
/// "Run linux (dev)" do VS Code).
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp]);
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
