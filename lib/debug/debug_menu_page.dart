import 'package:flutter/material.dart';

import '../dressing/palette.dart';
import 'debug_game_page.dart';
import 'scenario.dart';
import 'scenario_catalog.dart';

/// A lista de cenários. É a primeira tela do modo de desenvolvimento.
class DebugMenuPage extends StatelessWidget {
  const DebugMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.background,
      appBar: AppBar(
        title: const Text('Blocos — cenários'),
        backgroundColor: Palette.cardBackground,
        foregroundColor: Palette.textPrimary,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: scenarioCatalog.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) =>
            _ScenarioTile(scenario: scenarioCatalog[index]),
      ),
    );
  }
}

class _ScenarioTile extends StatelessWidget {
  const _ScenarioTile({required this.scenario});

  final Scenario scenario;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: Palette.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Palette.cardBorder),
      ),
      child: ListTile(
        title: Text(
          scenario.name,
          style: const TextStyle(
            color: Palette.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Text(
          scenario.purpose,
          style: TextStyle(color: Palette.textPrimary.withValues(alpha: 0.75)),
        ),
        trailing: const Icon(Icons.play_arrow, color: Palette.textPrimary),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => DebugGamePage(scenario: scenario),
          ),
        ),
      ),
    );
  }
}
