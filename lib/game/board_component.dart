import 'dart:math' as math;
import 'dart:ui';

// O Flame também exporta um Block, sem relação com o nosso.
import 'package:flame/components.dart' hide Block;
import 'package:flame/events.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';

import '../ui/block_look.dart';
import '../ui/palette.dart';
import 'block.dart';
import 'block_grid.dart';
import 'layout.dart';
import 'match_resolver.dart';
import 'score.dart';
import 'stack_raiser.dart';
import 'swap_controller.dart';

/// O tabuleiro na tela: tempo, geometria, toque e pintura. O estado dos blocos
/// é do [BlockGrid], as regras de troca são do [SwapController] e as
/// combinações são do [MatchResolver].
class BoardComponent extends PositionComponent
    with DragCallbacks, HasGameReference<FlameGame> {
  BoardComponent({required this.stackRaiser, required this.score});

  static const int columns = 6;
  static const int visibleRows = 12;

  /// Linhas de folga entre o topo do tabuleiro e a linha de perigo.
  static const int dangerRows = 2;

  /// Faixa reservada no topo para o HUD de placar/chain de uma etapa futura.
  static const double topReserve = 56;

  /// Um bloco sem apoio desce uma linha a cada passo.
  static const double fallStepSeconds = 0.035;

  final StackRaiser stackRaiser;
  final Score score;

  /// A linha extra é a que está entrando por baixo, fora da área visível.
  final grid = BlockGrid(columns: columns, rowCount: visibleRows + 1);

  late final swapController = SwapController(grid: grid);
  late final matchResolver = MatchResolver(grid: grid)
    ..onMatch = score.register;

  /// Quantas vezes o bloco combinado pisca por segundo.
  static const double flashHz = 6;

  double _riseOffset = 0;
  double _cellSize = 24;
  double _fallTimer = 0;

  /// Lado de cada tile em `assets/images/blocks.png` — o sprite sheet dos
  /// blocos, 6 colunas de 128×128 (ver [BlockLook.spriteColumn]).
  static const double spriteTileSize = 128;

  /// Quanto escurecer a linha que ainda está entrando por baixo, fora de
  /// jogo. Não é preto total: dá para planejar a próxima linha antes dela
  /// virar piso.
  static const double incomingShade = 0.55;

  final _panelPaint = Paint()..color = Palette.playfield;
  final _panelBorderPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..color = Palette.playfieldBorder;
  final _emptyCellPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1
    ..color = Palette.emptyCell;
  // Sem anti-aliasing: blocos vizinhos ficam colados borda a borda, e a
  // pilha sobe em fração contínua de pixel a cada frame (StackRaiser). Com
  // AA ligado, a borda de cada bloco suaviza contra o fundo de forma
  // independente do vizinho — e como a fração muda a cada frame, abre uma
  // frestinha de fundo entre os dois que treme/pisca. Sem AA a borda é dura
  // e os dois colam sem frincha, além de combinar mais com pixel art.
  final _spritePaint = Paint()
    ..isAntiAlias = false
    ..filterQuality = FilterQuality.none;
  final _overlayPaint = Paint()..isAntiAlias = false;

  late final Image _blocksImage;
  late final Image _selectorImage;

  @override
  Future<void> onLoad() async {
    _blocksImage = await Flame.images.load('blocks.png');
    _selectorImage = await Flame.images.load('selector.png');
  }

  final _dangerPaint = Paint()
    ..color = Palette.dangerLine
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round;

  // Ao contrário do sprite dos blocos (preenchimento sólido, sem AA/filtro
  // de propósito pra colar borda a borda sem frincha): o seletor é uma
  // imagem de linhas finas bem reduzida de tamanho, e a pilha sobe em
  // fração contínua de pixel. Sem filtro, a amostragem pula texels de
  // origem diferentes a cada frame — a linha treme. Com AA e filtro
  // melhor, o sub-pixel vira interpolação suave em vez de degrau.
  final _cursorPaint = Paint()
    ..isAntiAlias = true
    ..filterQuality = FilterQuality.medium;

  /// Geometria do board: célula, tamanho e posição. A largura vem do vão da
  /// porta na arte do gate ([GameLayout.boardVoidWidth]) — o board precisa
  /// caber exatamente aí, não no canvas inteiro. Alinhado pelo topo do vão
  /// ([GameLayout.boardVoidTop]), onde a passagem se abre — encostado ali
  /// não sobra vão morto entre a arte e o board. Estático e só função das
  /// constantes — não depende de nenhuma instância, então [WallComponent]
  /// pode calcular a mesma área sem depender da ordem de montagem dos dois
  /// componentes.
  static ({double cellSize, Vector2 size, Vector2 position}) layoutFor() {
    final cellSize = GameLayout.boardVoidWidth / columns;
    final size = Vector2(columns * cellSize, visibleRows * cellSize);
    final position = Vector2(GameLayout.boardVoidLeft, GameLayout.boardVoidTop);
    return (cellSize: cellSize, size: size, position: position);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    // Canvas fixo: o parâmetro `size` é o tamanho real do device, mas a
    // geometria do board é sempre a mesma (fixa no vão do gate) — a câmera
    // de resolução fixa é quem escala isso para o aparelho de verdade.
    final layout = layoutFor();
    _cellSize = layout.cellSize;
    this.size = layout.size;
    position = layout.position;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _riseOffset += stackRaiser.rowsPerSecond * dt;
    while (_riseOffset >= 1) {
      _riseOffset -= 1;
      grid.shiftUp();
    }

    _fallTimer += dt;
    while (_fallTimer >= fallStepSeconds) {
      _fallTimer -= fallStepSeconds;
      grid.applyGravityStep();
    }
    _easeFalls(dt);

    matchResolver.update(dt);
    stackRaiser.frozen = matchResolver.isResolving || grid.hasFallingBlocks;

    swapController.update(dt);
  }

  /// Derrete o rastro visual de quem acabou de cair uma linha. A taxa casa
  /// com [fallStepSeconds] de propósito: um bloco caindo várias linhas
  /// seguidas ganha +1 de rastro a cada passo e perde esse mesmo tanto antes
  /// do próximo, então o movimento sai contínuo em vez de picotado — sem essa
  /// coincidência, o rastro ia se acumular ou sumir rápido demais.
  void _easeFalls(double dt) {
    final decay = dt / fallStepSeconds;
    for (var index = 0; index < grid.rowCount; index++) {
      for (var col = 0; col < columns; col++) {
        final block = grid.atIndex(index, col);
        if (block != null && block.fallOffset > 0) {
          block.fallOffset = math.max(0, block.fallOffset - decay);
        }
      }
    }
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    final cell = _cellAt(game.camera.globalToLocal(event.canvasPosition));
    if (cell != null) {
      swapController.beginDrag(cell.col, cell.rowId);
    }
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    // event.localPosition vira NaN quando o dedo sai do componente. Convertendo
    // canvasPosition (sempre definido) pela câmera obtemos o ponto no mundo
    // (canvas de referência de GameLayout), que nunca fica indefinido.
    final worldX = game.camera.globalToLocal(event.canvasEndPosition).x;
    swapController.dragTo(_columnAt(worldX));
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    swapController.endDrag();
  }

  ({int col, int rowId})? _cellAt(Vector2 worldPoint) {
    final localX = worldPoint.x - position.x;
    final localY = worldPoint.y - position.y;
    if (localX < 0 || localY < 0 || localX >= size.x || localY >= size.y) {
      return null;
    }
    // Até o piso, nunca a linha que está entrando: ela ainda não está em jogo.
    final index = (localY / _cellSize + _riseOffset).floor().clamp(
      0,
      grid.floorIndex,
    );
    return (col: _columnAt(worldPoint.x), rowId: grid.rowIdAt(index));
  }

  int _columnAt(double worldX) =>
      ((worldX - position.x) / _cellSize).floor().clamp(0, columns - 1);

  /// Topo da linha que está no índice visual [index].
  double _topOf(int index) => (index - _riseOffset) * _cellSize;

  @override
  void render(Canvas canvas) {
    final panel = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Radius.circular(_cellSize * 0.2),
    );
    canvas.drawRRect(panel, _panelPaint);

    canvas.save();
    canvas.clipRRect(panel);
    _renderBlocks(canvas);
    _renderSwapAnimation(canvas);
    _renderCursor(canvas);
    canvas.restore();

    canvas.drawRRect(panel, _panelBorderPaint);
    _renderDangerLine(canvas);
  }

  void _renderBlocks(Canvas canvas) {
    final animation = swapController.animation;
    final animatedIndex = animation != null && grid.hasRow(animation.rowId)
        ? grid.indexOf(animation.rowId)
        : null;

    for (var index = 0; index < grid.rowCount; index++) {
      for (var col = 0; col < columns; col++) {
        // Os dois blocos da troca são desenhados depois, por cima de tudo.
        if (index == animatedIndex &&
            (col == animation!.grabbedCol || col == animation.displacedCol)) {
          continue;
        }
        final block = grid.atIndex(index, col);
        final left = col * _cellSize;
        final top = _topOf(index);
        if (block == null) {
          canvas.drawRect(
            Rect.fromLTWH(left, top, _cellSize, _cellSize),
            _emptyCellPaint,
          );
          continue;
        }

        final incoming = index == grid.incomingIndex;
        final fallingTop = top - block.fallOffset * _cellSize;
        switch (block.state) {
          case BlockState.idle:
            _drawSpriteBlock(
              canvas,
              block.color,
              left,
              fallingTop,
              overlayColor: incoming ? Palette.playfield : null,
              overlayAlpha: incoming ? incomingShade : 0,
            );
          case BlockState.matched:
            final piscada =
                (math.sin(block.stateTime * flashHz * 2 * math.pi) + 1) / 2;
            _drawSpriteBlock(
              canvas,
              block.color,
              left,
              fallingTop,
              overlayColor: Palette.flash,
              overlayAlpha: piscada,
            );
          case BlockState.popping:
            final saindo = block.stateTime < block.popDelay
                ? 0.0
                : ((block.stateTime - block.popDelay) /
                          MatchResolver.popDuration)
                      .clamp(0.0, 1.0);
            _drawSpriteBlock(
              canvas,
              block.color,
              left,
              fallingTop,
              scale: 1 - saindo,
              fadeOut: saindo,
            );
        }
      }
    }
  }

  /// Os dois blocos giram em torno do ponto entre eles, como uma porta
  /// giratória: o escolhido vem pela frente, e cresce porque está mais perto;
  /// o empurrado vai pelo fundo, encolhendo e desbotando. Eles se cruzam
  /// trocando de lado.
  ///
  /// No cruzamento os dois ficam no centro do vão e as bordas aparecem por um
  /// instante. Isso é geométrico: quem troca de lado tem que se cruzar. O que
  /// disfarça é o bloco da frente estar aumentado, cobrindo mais.
  void _renderSwapAnimation(Canvas canvas) {
    final animation = swapController.animation;
    if (animation == null || !grid.hasRow(animation.rowId)) {
      return;
    }
    final top = _topOf(grid.indexOf(animation.rowId));

    // Órbita: o x é a projeção do giro e o depth é o quanto saiu do plano.
    final sweep = (1 - math.cos(math.pi * animation.progress)) / 2;
    final depth = math.sin(math.pi * animation.progress);

    // O do fundo primeiro, para o da frente passar por cima dele.
    final displaced = grid.at(animation.rowId, animation.displacedCol);
    if (displaced != null) {
      // Recuo contido de propósito: encolhendo e desbotando muito, o bloco
      // do fundo desaparece atrás do da frente e o cruzamento vira buraco.
      _drawSpriteBlock(
        canvas,
        displaced.color,
        _orbit(animation.grabbedCol, animation.displacedCol, sweep),
        top,
        scale: 1 - 0.14 * depth,
        overlayColor: Palette.playfield,
        overlayAlpha: 0.18 * depth,
      );
    }

    final grabbed = grid.at(animation.rowId, animation.grabbedCol);
    if (grabbed != null) {
      _drawSpriteBlock(
        canvas,
        grabbed.color,
        _orbit(animation.displacedCol, animation.grabbedCol, sweep),
        top,
        scale: 1 + 0.3 * depth,
      );
    }
  }

  double _orbit(int from, int to, double sweep) =>
      (from + (to - from) * sweep) * _cellSize;

  Rect _spriteSrcRect(BlockColor color) => Rect.fromLTWH(
    color.look.spriteColumn * spriteTileSize,
    0,
    spriteTileSize,
    spriteTileSize,
  );

  /// Blocos vizinhos invadem uns aos outros por essa margem (em unidades do
  /// mundo, não de pixel de tela) em vez de encostar exatos. A pilha sobe em
  /// fração contínua de pixel, então uma borda encostada exata pode
  /// arredondar pra um lado ou outro a cada frame e abrir uma frincha do
  /// fundo entre os dois — some/aparece, lê como tremor. Com a invasão, o
  /// vizinho desenha por cima da frincha em vez de deixar o fundo aparecer;
  /// pequeno o bastante pra não dar pra perceber que os blocos não são
  /// perfeitamente 128×128 encostados.
  static const double _blockOverlap = 3;

  /// Desenha um bloco a partir de `blocks.png`, preenchendo a célula
  /// inteira (os tiles já nascem bordo-a-bordo, sem margem, mais a invasão
  /// de [_blockOverlap]). [overlayColor] tinge por cima (usado pra piscar
  /// branco na combinação, apagar a linha entrando, e desbotar o lado que
  /// perde na troca); [fadeOut] esmaece o sprite inteiro (usado no estouro,
  /// junto com o encolher de [scale]).
  void _drawSpriteBlock(
    Canvas canvas,
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
    final side = _cellSize * scale;
    final rect = Rect.fromLTWH(
      left + (_cellSize - side) / 2,
      top + (_cellSize - side) / 2,
      side,
      side,
    ).inflate(_blockOverlap);
    // Só o alpha do paint importa pro drawImageRect (RGB é ignorado sem
    // colorFilter) — branco é só convenção de leitura.
    _spritePaint.color = Color.fromRGBO(255, 255, 255, 1 - fadeOut);
    canvas.drawImageRect(
      _blocksImage,
      _spriteSrcRect(color),
      rect,
      _spritePaint,
    );
    if (overlayAlpha > 0 && overlayColor != null) {
      _overlayPaint.color = overlayColor.withAlpha(
        (overlayAlpha.clamp(0, 1) * 255).round(),
      );
      canvas.drawRect(rect, _overlayPaint);
    }
  }

  void _renderCursor(Canvas canvas) {
    final rowId = swapController.cursorRowId;
    if (rowId == null || !grid.hasRow(rowId)) {
      return;
    }
    final rect = Rect.fromLTWH(
      swapController.cursorCol * _cellSize,
      _topOf(grid.indexOf(rowId)),
      _cellSize * 2,
      _cellSize,
    );
    canvas.drawImageRect(
      _selectorImage,
      Rect.fromLTWH(
        0,
        0,
        _selectorImage.width.toDouble(),
        _selectorImage.height.toDouble(),
      ),
      rect,
      _cursorPaint,
    );
  }

  void _renderDangerLine(Canvas canvas) {
    const dash = 10.0;
    const gap = 6.0;
    final y = dangerRows * _cellSize;
    var x = 0.0;
    while (x < size.x) {
      final end = math.min(x + dash, size.x);
      canvas.drawLine(Offset(x, y), Offset(end, y), _dangerPaint);
      x = end + gap;
    }
  }
}
