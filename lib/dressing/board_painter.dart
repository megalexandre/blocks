import 'dart:math' as math;
import 'dart:ui';


import 'palette.dart';
import '../game/model/block.dart';
import '../game/model/column.dart';
import '../game/playfield.dart';
import 'block_sprites.dart';
import 'board_viewport.dart';
import 'factory_elements.dart';
import 'selector.dart';

/// Desenha o tabuleiro: painel, blocos, animação da troca, cursor e linha de
/// perigo. Lê o estado do jogo ([grid], [swapController]) mas não o altera —
/// quem cuida de tempo, toque e geometria é o `BoardComponent`, que a cada
/// quadro entrega aqui a medida da célula e onde a pilha está.
class BoardPainter {
  BoardPainter({required this.playfield, required FactoryElements elements})
      : _blocks = elements.blocks,
        _selector = elements.selector;

  /// Lido, nunca escrito: o pintor pergunta ao jogo onde está cada coisa.
  final Playfield playfield;

  /// Quantas vezes o bloco combinado pisca por segundo.
  static const double flashHz = 6;

  /// Quanto apagar a linha que ainda está entrando por baixo, fora de jogo.
  /// Não é preto total: dá para planejar a próxima linha antes dela virar
  /// piso.
  static const double incomingShade = 0.55;

  final BlockSprites _blocks;
  final Selector _selector;

  final _overlayPaint = Paint()..isAntiAlias = true;
  final _dangerPaint = Paint()
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round;
  final _veilPaint = Paint()..color = Palette.gameOverVeil;

  /// Desenha o quadro. Todas as medidas vêm em [view] — o pintor não guarda
  /// nenhuma delas entre um quadro e outro.
  void render(Canvas canvas, BoardViewport view) {
    // Recorte reto, e não arredondado: a moldura do pacote encosta nas quatro
    // bordas do vão, então o canto arredondado que o painel tinha nunca
    // apareceria — e arredondar aqui cortaria o bloco da quina.
    //
    // A paisagem saiu daqui e virou o `ScenarioComponent`. Enquanto ela era
    // desenhada depois deste recorte, ela não tinha como passar dos 768×1536,
    // e o que se quer agora é ela correndo por baixo do batente.
    final panel = Rect.fromLTWH(0, 0, view.size.x, view.size.y);
    canvas.save();
    canvas.clipRect(panel);
    _renderBlocks(canvas, view);
    _renderSwapAnimation(canvas, view);
    _renderCursor(canvas, view);
    canvas.restore();

    if (playfield.isOver) {
      canvas.drawRect(panel, _veilPaint);
    }
    _renderDangerLine(canvas, view);
  }

  void _renderBlocks(Canvas canvas, BoardViewport view) {
    final animation = playfield.swapAnimation;
    final animatedRow = animation == null
        ? null
        : playfield.grid.positionOf(animation.row);

    for (final row in playfield.geometry.allRows) {
      for (final col in playfield.geometry.columns) {
        // Os dois blocos da troca são desenhados depois, por cima de tudo.
        if (row == animatedRow &&
            (col == animation!.grabbedColumn ||
                col == animation.displacedColumn)) {
          continue;
        }
        final block = playfield.grid.blockAt(row, col);
        if (block == null) {
          continue;
        }
        final left = view.leftOf(col);
        final top = view.topOf(row) - block.fallOffset * view.cellSize;
        final incoming = row == playfield.geometry.incomingRow;

        switch (block.state) {
          case BlockState.idle:
            _drawBlock(
              canvas,
              view,
              block.color,
              left,
              top,
              overlayColor: incoming ? Palette.playfield : null,
              overlayAlpha: incoming ? incomingShade : 0,
            );
          case BlockState.matched:
            final flash =
                (math.sin(block.stateTime * flashHz * 2 * math.pi) + 1) / 2;
            _drawBlock(
              canvas,
              view,
              block.color,
              left,
              top,
              overlayColor: Palette.flash,
              overlayAlpha: flash,
            );
          case BlockState.popping:
            final popped = block.stateTime < block.popDelay
                ? 0.0
                : ((block.stateTime - block.popDelay) /
                          playfield.timings.pop)
                      .clamp(0.0, 1.0);
            _drawBlock(
              canvas,
              view,
              block.color,
              left,
              top,
              scale: 1 - popped,
              fadeOut: popped,
            );
        }
      }
    }
  }

  /// Os dois blocos giram em torno do ponto entre eles, como uma porta
  /// giratória: o escolhido vem pela frente e cresce porque está mais perto;
  /// o empurrado vai pelo fundo, encolhendo e desbotando.
  ///
  /// No cruzamento os dois ficam no centro do vão e as bordas aparecem por um
  /// instante. Isso é geométrico: quem troca de lado tem que se cruzar. O que
  /// disfarça é o bloco da frente estar aumentado, cobrindo mais.
  void _renderSwapAnimation(Canvas canvas, BoardViewport view) {
    final animation = playfield.swapAnimation;
    if (animation == null) {
      return;
    }
    // A linha pode ter saído pelo topo no meio da animação.
    final row = playfield.grid.positionOf(animation.row);
    if (row == null) {
      return;
    }
    final top = view.topOf(row);

    // Órbita: o x é a projeção do giro e o depth é o quanto saiu do plano.
    final sweep = (1 - math.cos(math.pi * animation.progress)) / 2;
    final depth = math.sin(math.pi * animation.progress);

    // O do fundo primeiro, para o da frente passar por cima dele.
    final displaced = animation.row[animation.displacedColumn];
    if (displaced != null) {
      // Recuo contido de propósito: encolhendo e desbotando muito, o bloco
      // do fundo desaparece atrás do da frente e o cruzamento vira buraco.
      _drawBlock(
        canvas,
        view,
        displaced.color,
        _orbit(
          view,
          animation.grabbedColumn,
          animation.displacedColumn,
          sweep,
        ),
        top,
        scale: 1 - 0.14 * depth,
        overlayColor: Palette.playfield,
        overlayAlpha: 0.18 * depth,
      );
    }

    final grabbed = animation.row[animation.grabbedColumn];
    if (grabbed != null) {
      _drawBlock(
        canvas,
        view,
        grabbed.color,
        _orbit(
          view,
          animation.displacedColumn,
          animation.grabbedColumn,
          sweep,
        ),
        top,
        scale: 1 + 0.3 * depth,
      );
    }
  }

  double _orbit(BoardViewport view, Column from, Column to, double sweep) =>
      view.leftOf(from) + (view.leftOf(to) - view.leftOf(from)) * sweep;

  /// Desenha um bloco preenchendo a célula. [overlayColor] tinge por cima
  /// (flash da combinação, linha entrando apagada, lado que perde na
  /// troca); [fadeOut] esmaece o sprite inteiro, usado no estouro junto com
  /// o encolher de [scale].
  void _drawBlock(
    Canvas canvas,
    BoardViewport view,
    BlockColor color,
    double left,
    double top, {
    double scale = 1,
    Color? overlayColor,
    double overlayAlpha = 0,
    double fadeOut = 0,
  }) {
    if (scale <= 0) {
      return;
    }
    final side = view.cellSize * scale;
    final rect = Rect.fromLTWH(
      left + (view.cellSize - side) / 2,
      top + (view.cellSize - side) / 2,
      side,
      side,
    );
    _blocks.render(canvas, color, rect, opacity: 1 - fadeOut);
    if (overlayAlpha > 0 && overlayColor != null) {
      _overlayPaint.color = overlayColor.withAlpha(
        (overlayAlpha.clamp(0, 1) * 255).round(),
      );
      canvas.drawRect(rect, _overlayPaint);
    }
  }

  void _renderCursor(Canvas canvas, BoardViewport view) {
    final cursorRow = playfield.cursorRow;
    final row = cursorRow == null ? null : playfield.grid.positionOf(cursorRow);
    if (row == null) {
      return;
    }
    _selector.render(
      canvas,
      Rect.fromLTWH(
        view.leftOf(playfield.cursorColumn),
        view.topOf(row),
        view.cellSize * 2,
        view.cellSize,
      ),
    );
  }

  /// A linha tracejada que marca a folga do topo.
  ///
  /// Muda de cor quando a pilha alcança essa folga. Antes de existir derrota
  /// ela era enfeite; agora é o único aviso que o jogador tem de que a
  /// próxima linha pode acabar com a partida.
  void _renderDangerLine(Canvas canvas, BoardViewport view) {
    const dash = 10.0;
    const gap = 6.0;
    _dangerPaint.color = playfield.isInDanger
        ? Palette.dangerLineAlert
        : Palette.dangerLine;
    final y = view.rowsToPixels(playfield.geometry.dangerRowCount);
    var x = 0.0;
    while (x < view.size.x) {
      final end = math.min(x + dash, view.size.x);
      canvas.drawLine(Offset(x, y), Offset(end, y), _dangerPaint);
      x = end + gap;
    }
  }
}
