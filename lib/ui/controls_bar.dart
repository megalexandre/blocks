import 'package:flutter/material.dart';

import '../game/blocos_game.dart';
import 'palette.dart';

class ControlsBar extends StatefulWidget {
  const ControlsBar({required this.game, super.key});

  final BlocosGame game;

  @override
  State<ControlsBar> createState() => _ControlsBarState();
}

class _ControlsBarState extends State<ControlsBar> {
  bool _boosting = false;
  bool _paused = false;

  void _setBoosting(bool value) {
    widget.game.stackRaiser.boosting = value;
    setState(() => _boosting = value);
  }

  void _togglePause() {
    final paused = !_paused;
    setState(() => _paused = paused);
    if (paused) {
      widget.game.pauseEngine();
    } else {
      widget.game.resumeEngine();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _RaiseButton(pressed: _boosting, onPressedChanged: _setBoosting),
          _PauseButton(paused: _paused, onTap: _togglePause),
        ],
      ),
    );
  }
}

class _RaiseButton extends StatelessWidget {
  const _RaiseButton({required this.pressed, required this.onPressedChanged});

  final bool pressed;
  final ValueChanged<bool> onPressedChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => onPressedChanged(true),
      onTapUp: (_) => onPressedChanged(false),
      onTapCancel: () => onPressedChanged(false),
      child: Container(
        width: 80,
        height: 56,
        decoration: BoxDecoration(
          color: pressed ? Palette.controlPressed : Palette.controlIdle,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Palette.controlBorder),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _bar(),
            const SizedBox(height: 7),
            _bar(),
          ],
        ),
      ),
    );
  }

  Widget _bar() => Container(
    width: 30,
    height: 3,
    decoration: BoxDecoration(
      color: Palette.controlIcon,
      borderRadius: BorderRadius.circular(2),
    ),
  );
}

class _PauseButton extends StatelessWidget {
  const _PauseButton({required this.paused, required this.onTap});

  final bool paused;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: paused ? Palette.controlPressed : Palette.controlIdle,
          shape: BoxShape.circle,
          border: Border.all(color: Palette.controlBorder),
        ),
        child: Icon(
          paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
          color: Palette.controlIcon,
          size: 28,
        ),
      ),
    );
  }
}
