import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:blocos/config/layout.dart';
import 'package:blocos/dressing/chain_badge_painter.dart';
import 'package:blocos/dressing/factory_elements.dart';
import 'package:blocos/game/board_script.dart';
import 'package:blocos/game/model/board_geometry.dart';
import 'package:blocos/game/playfield.dart';
import 'package:blocos/game/rules/random_dealer.dart';
import 'package:blocos/scene/board_component.dart';
import 'package:blocos/scene/chain_badge_component.dart';
import 'package:blocos/scene/game_scene.dart';
import 'package:blocos/scene/match_page.dart';
import 'package:blocos/scene/routes.dart';

/// A partida rodando de verdade, montada num `GameWidget`.
///
/// Pelo widget, e não por um `FlameGame` solto: é o laço do Flame que adia
/// entrada e saída de componente para fora da varredura da árvore, e fora dele
/// um selo que se remove no próprio `update` quebra a iteração. O que se
/// verifica aqui é justamente a ligação — a combinação virando selo montado na
/// cena, com o número certo, no lugar certo, e indo embora sozinho.
///
/// Nada de imagem: as folhas entram no cache global do Flame antes do teste
/// começar, porque dentro do tempo falso do `pumpWidget` um carregamento de
/// verdade nunca completaria.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final warm = FactoryElements();
    await warm.loadInterface();
    await warm.loadGame();
  });

  /// O tabuleiro do cenário "Chain 2": o trio vermelho estoura, os azuis
  /// perdem apoio, caem e fecham o segundo trio.
  Playfield chainOfTwo() {
    final playfield = Playfield(
      geometry: BoardGeometry.standard,
      dealer: RandomDealer.seeded(1),
    );
    BoardScript('''
      .BB...
      RRRB..
    ''').paintOn(playfield.grid);
    return playfield;
  }

  /// Abre a partida e devolve o tabuleiro montado, com a porta já fora do
  /// caminho — a pilha fica segurada, então o tabuleiro não escorre enquanto
  /// o teste anda.
  Future<BoardComponent> start(WidgetTester tester, GameScene scene) async {
    tester.view.physicalSize = GameLayout.size.toSize();
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(GameWidget(game: scene));
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    final page = scene.router.currentRoute.firstChild<MatchPage>()!;
    final board = page.children.whereType<BoardComponent>().first;
    scene.playfield.risePaused = true;
    return board;
  }

  List<ChainBadgeComponent> badgesOn(BoardComponent board) =>
      board.children.whereType<ChainBadgeComponent>().toList();

  /// Anda quadro a quadro até a condição valer.
  Future<void> stepUntil(
    WidgetTester tester,
    bool Function() done, {
    int maxSteps = 300,
  }) async {
    for (var i = 0; i < maxSteps; i++) {
      if (done()) {
        return;
      }
      await tester.pump(const Duration(milliseconds: 16));
    }
    fail('não aconteceu em $maxSteps quadros');
  }

  testWidgets('a chain de 2 solta um selo no tabuleiro, e chain 1 não', (
    tester,
  ) async {
    final scene = GameScene(
      createPlayfield: chainOfTwo,
      afterLoading: Routes.match,
    );
    final board = await start(tester, scene);

    // A primeira combinação é chain 1, e chain 1 não é notícia.
    await stepUntil(tester, () => scene.playfield.chainLevel == 1);
    expect(badgesOn(board), isEmpty);

    await stepUntil(tester, () => badgesOn(board).isNotEmpty);
    final badge = badgesOn(board).single;
    expect(badge.level, 2);
    expect(scene.playfield.chainLevel, 2);

    // Rente ao grupo que fechou, e não em cima do primeiro trio: quem fecha a
    // chain são os azuis das colunas 1, 2 e 3, então o selo nasce centrado na
    // coluna 2 — a do meio deles —, no piso, onde eles pousaram. Nunca com
    // meio selo para fora do tabuleiro.
    final cell = GameLayout.boardVoidWidth / BoardGeometry.standard.columnCount;
    expect(badge.position.x, cell * 2.5);
    expect(badge.position.y, greaterThan(board.size.y - cell * 2));
    expect(badge.position.x - badge.size.x / 2, greaterThanOrEqualTo(0));
    expect(badge.position.y + badge.size.y / 2, lessThanOrEqualTo(board.size.y));
  });

  testWidgets('o selo sobe e sai de cena sozinho', (tester) async {
    final scene = GameScene(
      createPlayfield: chainOfTwo,
      afterLoading: Routes.match,
    );
    final board = await start(tester, scene);
    await stepUntil(tester, () => badgesOn(board).isNotEmpty);
    final badge = badgesOn(board).single;
    final born = badge.position.y;

    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(
      badge.position.y,
      lessThan(born),
      reason: 'um terço de segundo depois o selo já tem que ter subido',
    );

    await stepUntil(tester, () => badgesOn(board).isEmpty);
    expect(badge.isMounted, isFalse);
  });

  test('o selo e o HUD usam o mesmo corte de nível', () {
    // Os dois anunciam a mesma chain. Se um mudar de corte sem o outro, o
    // jogador vê "CHAIN X2" na faixa de cima sem selo nenhum no tabuleiro.
    expect(ChainBadgePainter.minLevel, 2);
  });
}
