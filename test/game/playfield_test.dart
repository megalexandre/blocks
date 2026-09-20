import 'package:flutter_test/flutter_test.dart';

import 'package:blocos/game/board_script.dart';
import 'package:blocos/game/model/block.dart';
import 'package:blocos/game/model/column.dart';
import 'package:blocos/game/game_event.dart';
import 'package:blocos/game/playfield.dart';
import 'package:blocos/game/model/row_index.dart';
import 'package:blocos/game/rules/random_dealer.dart';
import 'package:blocos/game/rules/stack_raiser.dart';

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

  group('os momentos que viram som', () {
    /// Roda até [frames] quadros e devolve cada evento com o quadro em que
    /// saiu, para dar para medir o tempo entre um e outro.
    List<(int, GameEvent)> timeline(Playfield playfield, int frames) => [
      for (var f = 0; f < frames; f++)
        for (final event in playfield.update(frame)) (f, event),
    ];

    Playfield scripted(String drawing) {
      final playfield = seeded(20);
      BoardScript(drawing).paintOn(playfield.grid);
      return playfield;
    }

    test('o estouro começa uma vez por grupo, meio segundo depois do pisca', () {
      final playfield = scripted('''
        GBY...
        RRR...
      ''');

      final events = timeline(playfield, 120);
      final cleared = events.where((e) => e.$2 is MatchCleared).toList();
      final popped = events.where((e) => e.$2 is PopStarted).toList();

      expect(cleared, hasLength(1));
      expect(popped, hasLength(1), reason: 'um grupo, um início de estouro');
      expect((popped.single.$2 as PopStarted).count, 3);

      // O pisca dura 0,5 s: trinta quadros a 60 fps, com folga de um para o
      // arredondamento do acumulador.
      final gap = popped.single.$1 - cleared.single.$1;
      expect(gap, inInclusiveRange(29, 31),
          reason: 'o som do estouro tem que sair quando os blocos começam a '
              'sumir, não quando começam a piscar');
    });

    test('bloco que cai e fecha uma combinação ainda anuncia o pouso', () {
      // O caso que decidiu o desenho: o bloco chega e no mesmo quadro já
      // começa a piscar. Contando só quem "achou apoio e está parado", esse
      // impacto — justamente o que abre uma chain — nunca soaria.
      final playfield = scripted('''
        .BB...
        RRRB..
      ''');

      final events = timeline(playfield, 240);
      final chain2 = events.indexWhere(
        (e) => e.$2 is MatchCleared && (e.$2 as MatchCleared).chainLevel == 2,
      );
      expect(chain2, isNot(-1), reason: 'o cenário tinha que fechar chain 2');

      final landings = events
          .where((e) => e.$2 is BlocksLanded)
          .map((e) => (e.$2 as BlocksLanded).count)
          .fold(0, (a, b) => a + b);
      expect(
        landings,
        greaterThanOrEqualTo(2),
        reason: 'os dois azuis que caíram e fecharam o trio não soaram',
      );
    });
  });

  group('a derrota', () {
    /// Um tabuleiro cheio até o topo, subindo depressa: a próxima linha
    /// completa empurra bloco para fora.
    Playfield brimming() {
      final playfield = Playfield.standard(
        dealer: RandomDealer.seeded(3),
        raiser: StackRaiser(baseRowsPerSecond: 4),
      );
      final full = List.filled(
        playfield.geometry.visibleRowCount,
        'RGBYPR',
      ).join('\n');
      BoardScript(full).paintOn(playfield.grid);
      return playfield;
    }

    test('linha cheia saindo pelo topo emite ToppedOut e encerra', () {
      final playfield = brimming();
      expect(playfield.isOver, isFalse);

      final events = runUntil(playfield, () => playfield.isOver);

      expect(events.whereType<ToppedOut>(), hasLength(1));
      expect(playfield.isOver, isTrue);
    });

    test('depois de perder, o tempo não muda mais nada', () {
      final playfield = brimming();
      runUntil(playfield, () => playfield.isOver);

      final before = BoardScript.describe(playfield.grid);
      final rise = playfield.riseOffset;
      final score = playfield.score.total;

      for (var i = 0; i < 300; i++) {
        expect(
          playfield.update(frame),
          isEmpty,
          reason: 'um jogo encerrado não tem mais nada a anunciar',
        );
      }

      expect(BoardScript.describe(playfield.grid), before);
      expect(playfield.riseOffset, rise);
      expect(playfield.score.total, score);
    });

    test('nenhum quadro corre com bloco no teto', () {
      // Este é o invariante que separa "acaba quando o bloco chega ao teto"
      // de "acaba quando a linha do teto é descartada". No segundo caso o
      // bloco passa uma subida inteira na primeira linha, deslizando para
      // fora da área visível com o jogo ainda rodando — e é isso que se via
      // na tela: peças sumindo pelo teto sem a partida acabar.
      //
      // Medir `riseOffset` no fim não serve: ele é zerado no deslocamento nos
      // dois casos. O que denuncia é existir **algum** quadro com a linha do
      // topo ocupada e a partida ainda de pé.
      final playfield = Playfield.standard(
        dealer: RandomDealer.seeded(3),
        raiser: StackRaiser(baseRowsPerSecond: 4),
      );
      const cores = ['R', 'G', 'B'];
      BoardScript(
        List.generate(11, (i) => '..${cores[i % 3]}...').join('\n'),
      ).paintOn(playfield.grid);

      final top = playfield.geometry.topRow;
      var frames = 0;
      while (!playfield.isOver && frames < 2000) {
        playfield.update(frame);
        frames++;
        if (playfield.isOver) {
          break;
        }
        expect(
          playfield.grid.rowAt(top).isEmpty,
          isTrue,
          reason:
              'no quadro $frames havia bloco na linha do topo e a partida '
              'continuava — ele está saindo da tela em vez de encerrar o jogo',
        );
      }

      expect(playfield.isOver, isTrue, reason: 'a torre nunca derrubou o jogo');
      expect(
        playfield.grid.blockAt(top, col(2)),
        isNotNull,
        reason: 'o bloco que encerrou a partida tem que estar no teto',
      );
    });

    test('linha vazia sai pelo topo sem encerrar a partida', () {
      // A pilha sobe o tempo todo; perder é a linha sair **com bloco**, não
      // a linha sair. Por isso o teste para na primeira subida: deixar
      // rodando acabaria empurrando a pilha pintada até o topo.
      final playfield = Playfield.standard(
        dealer: RandomDealer.seeded(3),
        raiser: StackRaiser(baseRowsPerSecond: 4),
      );
      BoardScript('RGBYPR').paintOn(playfield.grid);

      var risen = false;
      for (var i = 0; i < 400 && !risen; i++) {
        for (final event in playfield.update(frame)) {
          risen |= event is RowsRisen;
        }
      }

      expect(risen, isTrue, reason: 'a pilha não chegou a subir uma linha');
      expect(
        playfield.isOver,
        isFalse,
        reason: 'as linhas que saíram estavam vazias',
      );
    });
  });

  group('acelerar a subida', () {
    /// Quanto a pilha subiu ao todo, em linhas.
    ///
    /// `riseOffset` sozinho não serve: ele é a **fração da linha atual** e
    /// zera a cada linha completa, então uma pilha veloz pode marcar menos
    /// que uma lenta. O total é as linhas inteiras mais a fração.
    double totalRise(Playfield playfield, int frames) {
      var rows = 0;
      for (var i = 0; i < frames; i++) {
        for (final event in playfield.update(frame)) {
          if (event is RowsRisen) {
            rows += event.count;
          }
        }
      }
      return rows + playfield.riseOffset;
    }

    test('segurando, a pilha sobe muito mais rápido', () {
      // O `boosting` existia desde sempre e nada em produção o acionava.
      // Agora que a faixa lateral o liga, a conta precisa ser afirmada aqui:
      // o botão promete ritmo, e é aqui que o ritmo mora.
      final calma = totalRise(seeded(40), 120);
      final apressada = totalRise(seeded(40)..boosting = true, 120);

      expect(
        apressada,
        greaterThan(calma * 4),
        reason: 'segurar mal acelerou: $apressada contra $calma linhas',
      );
    });

    test('soltar devolve o ritmo normal', () {
      final playfield = seeded(41)..boosting = true;
      final depressa = totalRise(playfield, 60);

      playfield.boosting = false;
      final devagar = totalRise(playfield, 60) - depressa;

      expect(
        devagar,
        lessThan(depressa / 4),
        reason: 'a pilha continuou acelerada depois de soltar',
      );
    });

    test('acelerar não vence o congelamento da pilha', () {
      // Enquanto uma combinação resolve, a pilha fica parada. Segurar o botão
      // não pode furar essa regra — senão dá para empurrar a pilha por cima
      // de um estouro em andamento.
      final playfield = seeded(42);
      _plantMatch(playfield);
      playfield.update(frame);
      playfield.boosting = true;

      final parada = playfield.riseOffset;
      for (var i = 0; i < 20; i++) {
        playfield.update(frame);
      }

      expect(playfield.riseOffset, parada);
    });
  });

  group('a zona de perigo', () {
    test('sem bloco na folga do topo, não há perigo', () {
      final playfield = seeded(30);
      BoardScript('RGBYPR').paintOn(playfield.grid);

      expect(playfield.isInDanger, isFalse);
    });

    test('um bloco na folga do topo já é perigo', () {
      final playfield = seeded(30);
      final full = List.filled(
        playfield.geometry.visibleRowCount,
        'RGBYPR',
      ).join('\n');
      BoardScript(full).paintOn(playfield.grid);

      expect(playfield.isInDanger, isTrue);
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
