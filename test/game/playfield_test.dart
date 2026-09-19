import 'package:flutter_test/flutter_test.dart';

import 'package:blocos/game/model/block.dart';
import 'package:blocos/game/model/column.dart';
import 'package:blocos/game/game_event.dart';
import 'package:blocos/game/playfield.dart';
import 'package:blocos/game/model/row_index.dart';
import 'package:blocos/game/rules/random_dealer.dart';

RowIndex row(int value) => RowIndex(value);
Column col(int value) => Column(value);

/// Um quadro de 60 fps. Os testes andam nesse passo para exercitar o mesmo
/// caminho que o jogo de verdade percorre.
const double frame = 1 / 60;

Playfield seeded([int seed = 1]) =>
    Playfield.standard(dealer: RandomDealer.seeded(seed));

/// Roda até [predicate] valer, e falha em vez de rodar para sempre.
List<GameEvent> runUntil(
  Playfield playfield,
  bool Function() predicate, {
  int maxFrames = 2000,
}) {
  final seen = <GameEvent>[];
  for (var i = 0; i < maxFrames; i++) {
    seen.addAll(playfield.update(frame));
    if (predicate()) {
      return seen;
    }
  }
  fail('a condição nunca aconteceu em $maxFrames quadros');
}

void main() {
  group('a ordem do quadro', () {
    test('um quadro longo não perde linhas nem pula passos de gravidade', () {
      // O acumulador da subida e o da queda têm que absorver um quadro
      // gordo: um `update` de um segundo precisa dar no mesmo que sessenta
      // de um sexagésimo. Era o tipo de coisa que só dava para conferir
      // subindo o Flame.
      final long = seeded(9);
      final short = seeded(9);

      long.update(1);
      for (var i = 0; i < 60; i++) {
        short.update(frame);
      }

      for (final r in long.geometry.allRows) {
        for (final c in long.geometry.columns) {
          expect(
            long.grid.blockAt(r, c)?.color,
            short.grid.blockAt(r, c)?.color,
            reason: 'as duas partidas divergiram em (${r.value}, ${c.value})',
          );
        }
      }
    });

    test('a linha nova entra cheia toda vez que a pilha sobe', () {
      // Encher a linha que entra deixou de ser da grade e passou a ser do
      // StackFiller; esquecer de chamá-lo esvaziaria o tabuleiro aos poucos,
      // e só apareceria um minuto depois de começar a jogar.
      final playfield = seeded(4);
      final incoming = playfield.geometry.incomingRow;
      var risen = 0;

      for (var i = 0; i < 2000 && risen < 3; i++) {
        for (final event in playfield.update(frame)) {
          if (event is! RowsRisen) {
            continue;
          }
          risen += event.count;
          for (final c in playfield.geometry.columns) {
            expect(
              playfield.grid.blockAt(incoming, c),
              isNotNull,
              reason: 'a coluna ${c.value} da linha de entrada ficou vazia',
            );
          }
        }
      }

      expect(risen, greaterThanOrEqualTo(3), reason: 'a pilha não subiu');
    });
  });

  group('o congelamento da pilha', () {
    test('a pilha não sobe enquanto uma combinação está resolvendo', () {
      final playfield = seeded(5);
      _plantMatch(playfield);

      // O primeiro quadro acha a combinação; o congelamento vale a partir do
      // seguinte, e é de propósito.
      playfield.update(frame);
      final offsetWhenFound = playfield.riseOffset;

      for (var i = 0; i < 20; i++) {
        playfield.update(frame);
      }

      expect(
        playfield.riseOffset,
        offsetWhenFound,
        reason: 'a pilha subiu enquanto a combinação piscava',
      );
    });

    test('a pilha volta a subir depois que tudo assenta', () {
      final playfield = seeded(6);
      _plantMatch(playfield);

      runUntil(playfield, () => playfield.chainLevel == 0);
      final settled = playfield.riseOffset;
      for (var i = 0; i < 30; i++) {
        playfield.update(frame);
      }

      expect(
        playfield.riseOffset,
        greaterThan(settled),
        reason: 'a pilha ficou travada depois de a combinação terminar',
      );
    });
  });

  group('o placar', () {
    test('soma exatamente uma vez por combinação, e não por quadro', () {
      // A combinação fica piscando por meio segundo — trinta quadros com
      // `comboSize` parado em 3. Um placar que lesse o campo a cada quadro
      // contaria trinta vezes.
      final playfield = seeded(7);
      _plantMatch(playfield);

      final events = runUntil(playfield, () => playfield.chainLevel == 0);
      final cleared = events.whereType<MatchCleared>().toList();

      expect(cleared, hasLength(1));
      expect(
        playfield.score.total,
        cleared.single.comboSize * 10 * cleared.single.chainLevel,
      );
    });

    test('a chain que termina emite ChainEnded uma vez só', () {
      final playfield = seeded(8);
      _plantMatch(playfield);

      final events = runUntil(playfield, () => playfield.chainLevel == 0);

      expect(events.whereType<ChainEnded>(), hasLength(1));
    });
  });

  group('a entrada do jogador', () {
    test('um gesto vale uma troca, por mais longe que o dedo vá', () {
      final playfield = seeded(10);
      final floor = playfield.geometry.floorRow;

      final left = playfield.grid.blockAt(floor, col(0));
      final right = playfield.grid.blockAt(floor, col(1));

      playfield.grab((row: floor, col: col(0)));
      playfield.dragTo(col(5));

      expect(playfield.grid.blockAt(floor, col(1)), same(left));
      expect(playfield.grid.blockAt(floor, col(0)), same(right));
      expect(
        playfield.grid.blockAt(floor, col(2)),
        isNot(same(left)),
        reason: 'arrastar até a coluna 5 não pode acumular cinco trocas',
      );
    });

    test('bloco que ainda está no ar não pode ser trocado', () {
      // `isIdle` sozinho não bastava: um bloco no meio do rastro de queda é
      // idle, e trocá-lo ali fazia o rastro seguir rodando na coluna nova.
      final playfield = seeded(11);
      final floor = playfield.geometry.floorRow;

      // Abre um buraco embaixo de um bloco e deixa ele começar a cair.
      final column = playfield.geometry.columns.firstWhere(
        (c) =>
            playfield.grid.blockAt(floor, c) != null &&
            playfield.grid.blockAt(floor.above, c) != null,
      );
      playfield.grid.clear(floor, column);
      // Dois quadros: um de 1/60 ainda não completa o passo de gravidade
      // (0,025 s), então o primeiro só acumula tempo e o segundo é que move.
      playfield.update(frame);
      playfield.update(frame);

      final falling = playfield.grid.blockAt(floor, column);
      expect(falling, isNotNull, reason: 'o bloco tinha que ter caído');
      expect(falling!.fallOffset, greaterThan(0));
      expect(falling.isIdle, isTrue, reason: 'ele é idle — esse era o ardil');
      expect(
        falling.isSettled,
        isFalse,
        reason: 'mas não está assentado, e é isso que barra a troca',
      );

      final neighbour = playfield.grid.blockAt(floor, column.right);
      playfield.grab((row: floor, col: column));
      playfield.dragTo(column.right);

      expect(
        playfield.grid.blockAt(floor, column),
        same(falling),
        reason: 'a troca aconteceu com um bloco que ainda estava no ar',
      );
      expect(playfield.grid.blockAt(floor, column.right), same(neighbour));
    });
  });

  group('a queda depois de uma combinação', () {
    test('a pilha de cima cai inteira, não em escada', () {
      // A cascata do estouro é escalonada da esquerda para a direita, e por
      // isso cada bloco somia da grade num instante diferente — a coluna da
      // esquerda liberava a célula um passo antes da de baixo à direita, e o
      // que estava por cima desabava em degraus. O grupo inteiro tem que sair
      // junto; o escalonamento é só do encolhimento na tela.
      final playfield = seeded(12);
      final floor = playfield.geometry.floorRow;

      for (final r in playfield.geometry.playableRows) {
        for (final c in playfield.geometry.columns) {
          playfield.grid.clear(r, c);
        }
      }
      // Trio vermelho no piso, e em cima de cada um uma cor diferente — se
      // fossem iguais eles combinariam entre si em vez de cair.
      const above = [BlockColor.blue, BlockColor.green, BlockColor.yellow];
      for (var c = 0; c < 3; c++) {
        playfield.grid.put(floor, col(c), Block(BlockColor.red));
        playfield.grid.put(floor.above, col(c), Block(above[c]));
      }
      final tops = [
        for (var c = 0; c < 3; c++) playfield.grid.blockAt(floor.above, col(c))!,
      ];

      final startedFalling = <int?>[null, null, null];
      for (var f = 0; f < 400; f++) {
        playfield.update(frame);
        for (var c = 0; c < 3; c++) {
          if (startedFalling[c] == null && tops[c].fallOffset > 0) {
            startedFalling[c] = f;
          }
        }
        if (startedFalling.every((v) => v != null)) {
          break;
        }
      }

      expect(
        startedFalling,
        everyElement(isNotNull),
        reason: 'algum bloco de cima nunca chegou a cair',
      );
      expect(
        startedFalling.toSet(),
        hasLength(1),
        reason:
            'as colunas começaram a cair em quadros diferentes '
            '($startedFalling) — a pilha desabou em escada',
      );
    });
  });

  test('a mesma semente dá o mesmo tabuleiro e os mesmos eventos', () {
    // Só possível com o carteador injetável: antes, todo bug que dependesse
    // do sorteio era irreprodutível.
    final a = seeded(99);
    final b = seeded(99);
    final eventsA = <String>[];
    final eventsB = <String>[];

    for (var i = 0; i < 900; i++) {
      eventsA.addAll(a.update(frame).map((e) => e.runtimeType.toString()));
      eventsB.addAll(b.update(frame).map((e) => e.runtimeType.toString()));
    }

    expect(eventsA, equals(eventsB));
    expect(eventsA, isNotEmpty, reason: 'a partida precisa ter acontecido');
    expect(a.score.total, b.score.total);
  });
}

/// Planta um trio pronto no piso, sem passar pelo sorteio.
void _plantMatch(Playfield playfield) {
  final floor = playfield.geometry.floorRow;
  for (final c in playfield.geometry.columns) {
    playfield.grid.put(floor, c, Block(BlockColor.red));
  }
}
