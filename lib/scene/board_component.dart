import 'dart:ui';

// O Flame também exporta um Block, sem relação com o nosso.
import 'package:flame/components.dart' hide Block;
import 'package:flame/events.dart';
import 'package:flame/game.dart';

import '../game/game_event.dart';
import '../game/model/cell.dart';
import '../game/model/column.dart';
import '../game/playfield.dart';
import '../dressing/board_painter.dart';
import '../dressing/board_viewport.dart';
import '../dressing/chain_badge_painter.dart';
import '../dressing/factory_elements.dart';
import '../dressing/game_sounds.dart';
import '../config/layout.dart';
import 'chain_badge_component.dart';

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

  /// Elementos já carregados, entregues pela cena.
  final FactoryElements elements;

  /// O jogo. Este componente só o consulta e o alimenta com o tempo e o
  /// toque; quem sabe o que fazer com os dois é ele.
  final Playfield playfield;

  double _cellSize = 24;

  late final _painter = BoardPainter(
    playfield: playfield,
    elements: elements,
  );

  /// Um pintor para todos os selos: o que muda de um selo para o outro é o
  /// número e o retângulo, e os dois chegam na chamada.
  late final _badges = ChainBadgePainter(elements);

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
      if (event case MatchCleared(:final chainLevel, :final at)
          when chainLevel >= ChainBadgePainter.minLevel) {
        _showChainBadge(chainLevel, at);
      }
    }
  }

  /// Solta o selo do multiplicador rente ao grupo que acabou de fechar.
  ///
  /// A conversão para pixel é feita **aqui, no quadro do evento**: a linha que
  /// veio nele é posição visual, e ela muda de significado na próxima subida
  /// da pilha — um selo que guardasse a linha ficaria apontando para outro
  /// lugar do tabuleiro no meio do próprio voo. Em pixel ele fica onde a
  /// combinação foi, que é o que o jogador viu.
  void _showChainBadge(int level, Cell at) {
    final badge = ChainBadgePainter.sizeFor(level);
    final center = Vector2(
      (at.col.value + 0.5) * _cellSize,
      (at.row.value + 0.5 - playfield.riseOffset) * _cellSize,
    );
    add(
      ChainBadgeComponent(
        level: level,
        painter: _badges,
        position: _insideBoard(center, badge),
        size: Vector2(badge.width, badge.height),
      ),
    );
  }

  /// Puxa o selo para dentro do tabuleiro. Numa combinação encostada na borda
  /// ele nasceria metade fora, e fora do tabuleiro quem manda no pixel é o
  /// batente da moldura — o selo sairia cortado pela madeira.
  Vector2 _insideBoard(Vector2 center, Size badge) => Vector2(
    _within(center.x, badge.width, size.x),
    _within(center.y, badge.height, size.y),
  );

  /// Um eixo do encaixe. Quando o selo é **maior** que o espaço, ele fica
  /// centrado em vez de estourar: `clamp` recusa um limite de baixo maior que
  /// o de cima, e o espaço aqui pode ser zero — um quadro antes da primeira
  /// medida, o componente ainda não tem tamanho nenhum.
  static double _within(double center, double badge, double space) =>
      space < badge ? space / 2 : center.clamp(badge / 2, space - badge / 2);

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
