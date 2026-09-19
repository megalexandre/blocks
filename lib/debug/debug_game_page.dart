import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../dressing/palette.dart';
import '../scene/game_scene.dart';
import 'board_debug_overlay.dart';
import 'scenario.dart';

/// O cenário rodando, com a barra de ferramentas por cima.
///
/// A barra é widget Flutter num [Stack], e não um overlay do Flame: ela só
/// precisa ficar por cima do canvas, e o sistema de overlays só valeria a
/// pena se o menu tivesse que abrir no meio da partida.
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

  GameScene _build() => GameScene(playfield: widget.scenario.build());

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
    _scene.world.add(BoardDebugOverlay(playfield: _scene.playfield));
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
        // Coluna, e não pilha: por cima do canvas a barra escondia o rodapé
        // do tabuleiro, e com ele a linha que está entrando por baixo — que é
        // justamente uma das coisas que se quer enxergar aqui.
        child: Column(
          children: [
            Expanded(
              child: GameWidget(key: ValueKey(_generation), game: _scene),
            ),
            SizedBox(
              width: double.infinity,
              child: _Toolbar(
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: const BoxDecoration(
        color: Palette.cardBackground,
        border: Border(top: BorderSide(color: Palette.cardBorder)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            scenarioName,
            style: const TextStyle(
              color: Palette.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            runSpacing: 4,
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
            ],
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: active ? Palette.playfieldBorder : Colors.transparent,
          border: Border.all(color: Palette.cardBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
