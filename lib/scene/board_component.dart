import 'dart:ui';

// O Flame também exporta um Block, sem relação com o nosso.
import 'package:flame/components.dart' hide Block;
import 'package:flame/events.dart';
import 'package:flame/game.dart';

import '../game/model/cell.dart';
import '../game/model/column.dart';
import '../game/playfield.dart';
import '../dressing/board_painter.dart';
import '../dressing/board_viewport.dart';
import '../dressing/factory_elements.dart';
import '../dressing/game_sounds.dart';
import '../config/layout.dart';

/// O tabuleiro na tela: **geometria em pixel, toque e pintura**.
///
/// Não conduz mais o tempo: o quadro inteiro é do [Playfield], que é Dart
/// puro. O que sobrou aqui é o que só existe por causa do Flame — converter
/// um toque em célula, e entregar ao pintor as medidas do quadro.
class BoardComponent extends PositionComponent
    with DragCallbacks, HasGameReference<FlameGame> {
  BoardComponent({required this.playfield, required this.elements});

  static const int columns = 6;
  static const int visibleRows = 12;

  /// Linhas de folga entre o topo do tabuleiro e a linha de perigo.
  static const int dangerRows = 2;

  /// Elementos já carregados, entregues pela cena.
  final FactoryElements elements;

  /// O jogo. Este componente só o consulta e o alimenta com o tempo e o
  /// toque; quem sabe o que fazer com os dois é ele.
  final Playfield playfield;

  double _cellSize = 24;

  late final _painter = BoardPainter(
    playfield: playfield,
    dangerRows: dangerRows,
    elements: elements,
  );

  /// Geometria do board: célula, tamanho e posição. A largura vem do vão da
  /// porta na arte do gate ([GameLayout.boardVoidWidth]) — o board precisa
  /// caber exatamente aí, não no canvas inteiro. Alinhado pelo topo do vão
  /// ([GameLayout.boardVoidTop]), onde a passagem se abre — encostado ali
  /// não sobra vão morto entre a arte e o board. Estático e só função das
  /// constantes: qualquer componente que precise encostar no board calcula a
  /// mesma área sem depender da ordem de montagem entre os dois.
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
    // O placar já é somado pelo próprio Playfield; aqui escuta quem só existe
    // por causa da tela e do alto-falante.
    for (final event in playfield.update(dt)) {
      GameSounds.instance.handle(event);
    }
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    final cell = _cellAt(game.camera.globalToLocal(event.canvasPosition));
    if (cell != null) {
      playfield.grab(cell);
    }
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    // event.localPosition vira NaN quando o dedo sai do componente. Convertendo
    // canvasPosition (sempre definido) pela câmera obtemos o ponto no mundo
    // (canvas de referência de GameLayout), que nunca fica indefinido.
    final worldX = game.camera.globalToLocal(event.canvasEndPosition).x;
    playfield.dragTo(_columnAt(worldX));
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    playfield.release();
  }

  Cell? _cellAt(Vector2 worldPoint) {
    final localX = worldPoint.x - position.x;
    final localY = worldPoint.y - position.y;
    if (localX < 0 || localY < 0 || localX >= size.x || localY >= size.y) {
      return null;
    }
    // Até o piso, nunca a linha que está entrando: ela ainda não está em jogo.
    final raw = (localY / _cellSize + playfield.riseOffset).floor();
    return (
      col: _columnAt(worldPoint.x),
      row: playfield.geometry.clampPlayableRow(raw),
    );
  }

  Column _columnAt(double worldX) =>
      playfield.geometry.clampColumn(((worldX - position.x) / _cellSize).floor());

  @override
  void render(Canvas canvas) {
    _painter.render(
      canvas,
      BoardViewport(
        size: size,
        cellSize: _cellSize,
        riseOffset: playfield.riseOffset,
        zoom: game.camera.viewfinder.zoom,
      ),
    );
  }
}
