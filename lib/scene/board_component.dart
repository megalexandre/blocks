import 'dart:ui';

// O Flame também exporta um Block, sem relação com o nosso.
import 'package:flame/components.dart' hide Block;
import 'package:flame/events.dart';
import 'package:flame/game.dart';

import '../game/block_grid.dart';
import '../dressing/board_painter.dart';
import '../dressing/factory_elements.dart';
import '../config/layout.dart';
import '../game/match_resolver.dart';
import '../game/score.dart';
import '../game/stack_raiser.dart';
import '../game/swap_controller.dart';

/// O tabuleiro na tela: tempo, geometria, toque e pintura. O estado dos blocos
/// é do [BlockGrid], as regras de troca são do [SwapController] e as
/// combinações são do [MatchResolver].
class BoardComponent extends PositionComponent
    with DragCallbacks, HasGameReference<FlameGame> {
  BoardComponent({
    required this.stackRaiser,
    required this.score,
    required this.elements,
  });

  static const int columns = 6;
  static const int visibleRows = 12;

  /// Linhas de folga entre o topo do tabuleiro e a linha de perigo.
  static const int dangerRows = 2;

  /// Um bloco sem apoio desce uma linha a cada passo.
  static const double fallStepSeconds = 0.035;

  /// Elementos já carregados, entregues pela cena.
  final FactoryElements elements;

  final StackRaiser stackRaiser;
  final Score score;

  /// A linha extra é a que está entrando por baixo, fora da área visível.
  final grid = BlockGrid(columns: columns, rowCount: visibleRows + 1);

  late final swapController = SwapController(grid: grid);
  late final matchResolver = MatchResolver(grid: grid)
    ..onMatch = score.register;

  double _riseOffset = 0;
  double _cellSize = 24;
  double _fallTimer = 0;


  late final _painter = BoardPainter(
    grid: grid,
    swapController: swapController,
    dangerRows: dangerRows,
    elements: elements,
  );

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
    grid.easeFalls(dt, fallStepSeconds: fallStepSeconds);

    matchResolver.update(dt);
    stackRaiser.frozen = matchResolver.isResolving || grid.hasFallingBlocks;

    swapController.update(dt);
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

  @override
  void render(Canvas canvas) {
    _painter.render(
      canvas,
      size: size,
      cellSize: _cellSize,
      riseOffset: _riseOffset,
      zoom: game.camera.viewfinder.zoom,
    );
  }
}
