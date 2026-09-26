import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../dressing/palette.dart';
import '../scene/game_scene.dart';
import '../scene/routes.dart';
import 'board_debug_overlay.dart';
import 'scenario.dart';

/// O cenário rodando, com a barra de ferramentas na borda de cima.
///
/// A barra é widget Flutter, e não um overlay do Flame: ela só precisa ficar
/// fora do canvas, e o sistema de overlays só valeria a pena se o menu tivesse
/// que abrir no meio da partida.
class DebugGamePage extends StatefulWidget {
  const DebugGamePage({required this.scenario, super.key});

  final Scenario scenario;

  @override
  State<DebugGamePage> createState() => _DebugGamePageState();
}

class _DebugGamePageState extends State<DebugGamePage> {
  /// Sobe a cada recarga. Entra na chave do [GameWidget] para o Flutter
  /// jogar fora o jogo antigo em vez de reaproveitá-lo — sem isso, recarregar
  /// manteria o tabuleiro de antes na tela.
  int _generation = 0;

  late GameScene _scene = _build();
  bool _showData = false;
  bool _stepping = false;

  /// Entrega a **receita** do cenário, e não um jogo pronto: assim o botão
  /// "jogar de novo" do fim de partida remonta este mesmo cenário, em vez de
  /// cair numa partida normal.
  /// Passa direto do carregamento para a partida: o menu do jogo não interessa
  /// aqui — quem escolhe o que rodar é o menu de cenários, que já ficou para
  /// trás quando esta tela abriu.
  GameScene _build() => GameScene(
        createPlayfield: widget.scenario.build,
        afterLoading: Routes.match,
      );

  /// Monta o cenário de novo, do quadro zero.
  ///
  /// Mantém o passo a passo e a sobreposição ligados: recarregar **estando**
  /// em passo a passo é o fluxo principal desta tela — é como se caminha pela
  /// combinação desde o começo. Desligar aqui fazia o cenário resolver
  /// sozinho antes do primeiro passo.
  void _reload() {
    setState(() {
      _generation++;
      _scene = _build()..paused = _stepping;
      if (_showData) {
        _addOverlay();
      }
    });
  }

  void _addOverlay() {
    _scene.world.add(BoardDebugOverlay());
  }

  void _toggleData() {
    setState(() {
      _showData = !_showData;
      if (_showData) {
        _addOverlay();
      } else {
        _scene.world.removeWhere((c) => c is BoardDebugOverlay);
      }
    });
  }

  void _toggleRise() {
    setState(() {
      _scene.playfield.risePaused = !_scene.playfield.risePaused;
    });
  }

  /// Entra em modo passo a passo, ou sai dele.
  ///
  /// Usa o `paused` do próprio Flame, e não um congelamento nosso: o motor já
  /// sabe parar o relógio e avançar um quadro medido com [Game.stepEngine].
  void _toggleStepping() {
    setState(() {
      _stepping = !_stepping;
      _scene.paused = _stepping;
    });
  }

  void _stepOnce() => _scene.stepEngine();

  @override
  Widget build(BuildContext context) {
    final risePaused = _scene.playfield.risePaused;
    return Scaffold(
      backgroundColor: Palette.background,
      body: SafeArea(
        // Coluna, e não pilha: por cima do canvas a barra taparia o placar,
        // que é onde o contador de chain aparece. Fora do canvas ela não tapa
        // nada — e o preço é a altura que ela ocupa, que sai do jogo.
        //
        // Por isso ela é uma linha só de ícones, e não o cartão de duas
        // linhas com rótulo em cada botão que havia antes: cada pixel de
        // altura daqui é um pixel a menos de tabuleiro.
        //
        // Na borda de **cima**, e não na de baixo: o que se olha nesta tela é
        // a pilha subindo e a linha que entra por baixo, então a ferramenta
        // fica no canto mais longe disso.
        child: Column(
          children: [
            _Toolbar(
              scenarioName: widget.scenario.name,
              risePaused: risePaused,
              stepping: _stepping,
              showData: _showData,
              onBack: () => Navigator.of(context).pop(),
              onToggleRise: _toggleRise,
              onToggleStepping: _toggleStepping,
              onStep: _stepping ? _stepOnce : null,
              onReload: _reload,
              onToggleData: _toggleData,
            ),
            Expanded(
              child: GameWidget(
                key: ValueKey(_generation),
                game: _scene,
                loadingBuilder: (_) =>
                    const ColoredBox(color: Palette.background),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.scenarioName,
    required this.risePaused,
    required this.stepping,
    required this.showData,
    required this.onBack,
    required this.onToggleRise,
    required this.onToggleStepping,
    required this.onStep,
    required this.onReload,
    required this.onToggleData,
  });

  final String scenarioName;
  final bool risePaused;
  final bool stepping;
  final bool showData;
  final VoidCallback onBack;
  final VoidCallback onToggleRise;
  final VoidCallback onToggleStepping;
  final VoidCallback? onStep;
  final VoidCallback onReload;
  final VoidCallback onToggleData;

  /// Altura da barra. Fixa e pequena de propósito: é o tanto que o jogo
  /// perde de altura, então ela é o menor botão tocável que ainda dá para
  /// acertar — e não cresce com o rótulo, que virou dica de passar o mouse.
  static const double height = 34;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: const BoxDecoration(
        color: Palette.cardBackground,
        border: Border(bottom: BorderSide(color: Palette.cardBorder)),
      ),
      child: Row(
        children: [
          _Action(icon: Icons.arrow_back, label: 'Menu', onTap: onBack),
          _Action(
            icon: risePaused ? Icons.play_arrow : Icons.pause,
            label: risePaused ? 'Subir' : 'Segurar',
            active: risePaused,
            onTap: onToggleRise,
          ),
          _Action(
            icon: Icons.slow_motion_video,
            label: 'Passo a passo',
            active: stepping,
            onTap: onToggleStepping,
          ),
          _Action(
            icon: Icons.skip_next,
            label: '+1 quadro',
            onTap: onStep,
          ),
          _Action(
            icon: Icons.refresh,
            label: 'Recarregar',
            onTap: onReload,
          ),
          _Action(
            icon: Icons.grid_on,
            label: 'Dados',
            active: showData,
            onTap: onToggleData,
          ),
          const SizedBox(width: 8),
          // O nome fica no fim e encolhe com reticências: numa janela
          // estreita quem some é o texto, nunca um botão.
          Expanded(
            child: Text(
              scenarioName,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Palette.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final color = !enabled
        ? Palette.textPrimary.withValues(alpha: 0.3)
        : Palette.textPrimary;
    // O rótulo virou dica: ele é o que explicava o botão, e continua a um
    // segundo de distância, sem custar altura nenhuma à barra.
    return Tooltip(
      message: label,
      waitDuration: const Duration(milliseconds: 400),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 30,
          margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: active ? Palette.playfieldBorder : Colors.transparent,
            border: Border.all(color: Palette.cardBorder),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}
