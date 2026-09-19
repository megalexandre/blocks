import 'package:flame/components.dart' hide Block;
import 'package:flame/game.dart';
import 'package:flutter/painting.dart';

import '../dressing/board_viewport.dart';
import '../game/model/block.dart';
import '../game/playfield.dart';
import '../scene/board_component.dart';

/// Escreve por cima do tabuleiro o que o desenho esconde: em que linha e
/// coluna cada célula está, o estado de cada bloco e o rastro de queda dele.
///
/// Componente à parte, e não um modo do pintor: o pintor é da camada de
/// vestimenta e desenha o jogo como ele deve ser visto. Isto aqui é
/// ferramenta de desenvolvimento, some inteiro do aplicativo publicado, e
/// pode ser tirado e posto sem mexer em nada do desenho de verdade.
///
/// Usa [BoardComponent.layoutFor] para achar a mesma área do tabuleiro. O doc
/// desse método já previa este caso: ele é estático justamente para que
/// qualquer componente que precise encostar no board calcule a área sem
/// depender da ordem de montagem entre os dois.
class BoardDebugOverlay extends PositionComponent
    with HasGameReference<FlameGame> {
  BoardDebugOverlay({required this.playfield})
    : super(priority: 100); // por cima do tabuleiro

  final Playfield playfield;

  double _cellSize = 24;

  static const _cellStyle = TextStyle(
    color: Color(0xFF1A1A1A),
    fontSize: 13,
    fontWeight: FontWeight.w700,
  );
  static const _gutterStyle = TextStyle(
    color: Color(0xFF8A6A4A),
    fontSize: 15,
    fontWeight: FontWeight.w800,
  );
  static const _headerStyle = TextStyle(
    color: Color(0xFF1A1A1A),
    fontSize: 20,
    fontWeight: FontWeight.w800,
  );

  final _cellText = TextPaint(style: _cellStyle);
  final _gutterText = TextPaint(style: _gutterStyle);
  final _headerText = TextPaint(style: _headerStyle);

  final _cellBackdrop = Paint()..color = const Color(0x99FFFFFF);

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    final layout = BoardComponent.layoutFor();
    _cellSize = layout.cellSize;
    this.size = layout.size;
    position = layout.position;
  }

  @override
  void render(Canvas canvas) {
    final view = BoardViewport(
      size: size,
      cellSize: _cellSize,
      riseOffset: playfield.riseOffset,
      zoom: game.camera.viewfinder.zoom,
    );
    final geometry = playfield.geometry;

    _headerText.render(
      canvas,
      'chain ${playfield.chainLevel}   '
      'subida ${playfield.riseOffset.toStringAsFixed(2)}'
      '${playfield.risePaused ? " (parada)" : ""}',
      Vector2(0, -56),
    );

    for (final col in geometry.columns) {
      _gutterText.render(
        canvas,
        '${col.value}',
        Vector2(view.leftOf(col) + _cellSize / 2, -8),
        anchor: Anchor.bottomCenter,
      );
    }

    for (final row in geometry.allRows) {
      final top = view.topOf(row);
      // A linha de entrada e as que já saíram pelo topo não interessam aqui.
      if (top < -_cellSize || top > size.y) {
        continue;
      }
      _gutterText.render(
        canvas,
        '${row.value}',
        Vector2(-8, top + _cellSize / 2),
        anchor: Anchor.centerRight,
      );

      for (final col in geometry.columns) {
        final block = playfield.grid.blockAt(row, col);
        if (block == null) {
          continue;
        }
        final label = _labelFor(block);
        if (label.isEmpty) {
          continue;
        }
        final at = Vector2(
          view.leftOf(col) + 2,
          top - block.fallOffset * _cellSize + 2,
        );
        canvas.drawRect(
          Rect.fromLTWH(at.x - 1, at.y - 1, _cellSize - 4, 16),
          _cellBackdrop,
        );
        _cellText.render(canvas, label, at);
      }
    }
  }

  /// O que vale dizer sobre o bloco. Vazio quando não há nada de anormal —
  /// um tabuleiro parado fica legível em vez de virar um muro de texto.
  String _labelFor(Block block) {
    final parts = <String>[];
    if (!block.isIdle) {
      parts.add(block.state == BlockState.matched ? 'pisca' : 'estoura');
    }
    if (block.fallOffset > 0) {
      parts.add('↓${block.fallOffset.toStringAsFixed(2)}');
    }
    return parts.join(' ');
  }
}
