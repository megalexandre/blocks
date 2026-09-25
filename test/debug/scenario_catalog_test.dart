import 'package:flutter_test/flutter_test.dart';

import 'package:blocos/debug/scenario_catalog.dart';
import 'package:blocos/game/board_script.dart';
import 'package:blocos/game/game_event.dart';
import 'package:blocos/game/model/block.dart';
import 'package:blocos/game/model/column.dart';
import 'package:blocos/game/model/row_index.dart';
import 'package:blocos/game/playfield.dart';

void main() {
  test('todo cenário do catálogo monta sem estourar', () {
    // Um desenho com largura errada ou uma letra que não é cor só falharia ao
    // abrir aquele item do menu. Aqui falha no `flutter test`, que é onde dá
    // para ver.
    expect(scenarioCatalog, isNotEmpty);

    for (final scenario in scenarioCatalog) {
      expect(
        scenario.build,
        returnsNormally,
        reason: 'o cenário "${scenario.name}" não montou',
      );
    }
  });

  test('o desenho de cada cenário cabe no tabuleiro que ele monta', () {
    for (final scenario in scenarioCatalog) {
      final playfield = scenario.build();
      final drawing = scenario.board?.lines ?? const [];
      for (final line in drawing) {
        expect(
          line.length,
          playfield.geometry.columnCount,
          reason: 'linha "$line" do cenário "${scenario.name}"',
        );
      }
      expect(
        drawing.length,
        lessThanOrEqualTo(playfield.geometry.visibleRowCount),
        reason: 'o cenário "${scenario.name}" é mais alto que o tabuleiro',
      );
    }
  });

  test('o tabuleiro montado é o que o desenho pediu', () {
    // Ida e volta pelo formato: garante que `build` aplicou o desenho em vez
    // de deixar a pilha de abertura sorteada.
    for (final scenario in scenarioCatalog) {
      final board = scenario.board;
      if (board == null) {
        continue;
      }
      final described = BoardScript.describe(scenario.build().grid);
      expect(
        described.endsWith(board.lines.join('\n')),
        isTrue,
        reason:
            'o cenário "${scenario.name}" montou um tabuleiro diferente do '
            'desenho:\n$described',
      );
    }
  });

  test('cada cenário tem nome e propósito, que é o que o menu mostra', () {
    for (final scenario in scenarioCatalog) {
      expect(scenario.name.trim(), isNotEmpty);
      expect(
        scenario.purpose.trim(),
        isNotEmpty,
        reason: 'sem propósito, o item do menu não diz o que olhar',
      );
    }
  });

  test('os nomes não se repetem', () {
    final names = scenarioCatalog.map((s) => s.name).toList();
    expect(names.toSet(), hasLength(names.length));
  });

  test('nenhum cenário nasce com a partida já perdida', () {
    // A linha do topo é o teto: um bloco ali encerra o jogo no primeiro
    // quadro. Foi assim que "Queda alta" quebrou — ele desenhava o bloco na
    // linha 0, que era jogável até a derrota passar a valer na chegada.
    //
    // Um cenário que acaba antes de ser visto não serve para nada, e o
    // sintoma na tela é mudo: a tela abre já com o painel de fim de jogo.
    for (final scenario in scenarioCatalog) {
      final playfield = scenario.build();
      playfield.update(1 / 60);
      expect(
        playfield.isOver,
        isFalse,
        reason: 'o cenário "${scenario.name}" acaba no primeiro quadro',
      );
    }
  });

  group('os cenários de chain chegam ao número que prometem', () {
    // O que faltava quando o "Chain 3" parou de chegar a 3: nenhum teste
    // olhava o número, então o cenário continuou no menu prometendo uma coisa
    // e mostrando outra. Só se vê rodando o cenário até o fim.
    const frame = 1 / 60;

    /// O maior nível de chain que o cenário alcança sozinho, e o tamanho de
    /// cada combinação no caminho.
    (int, List<int>) chainOf(Playfield playfield) {
      var top = 0;
      final combos = <int>[];
      for (var f = 0; f < 60 * 20; f++) {
        for (final event in playfield.update(frame)) {
          if (event is MatchCleared) {
            top = event.chainLevel > top ? event.chainLevel : top;
            combos.add(event.comboSize);
          }
        }
      }
      return (top, combos);
    }

    for (final expected in [2, 3]) {
      test('Chain $expected fecha $expected elos de três blocos', () {
        final scenario = scenarioCatalog.firstWhere(
          (s) => s.name == 'Chain $expected',
        );
        final (top, combos) = chainOf(scenario.build());

        expect(top, expected, reason: 'a chain do cenário "${scenario.name}"');
        // O tamanho importa junto: quando dois elos fecham no mesmo quadro
        // eles viram um grupo só, e a chain some sem ninguém notar — o número
        // que aparece é um combo grande, não uma chain curta.
        expect(
          combos,
          List.filled(expected, 3),
          reason: 'cada elo tem que ser uma trinca separada',
        );
      });
    }
  });

  test('o azul de "Passa reto pelo par" só combina quando pousa', () {
    // O cenário existe para isto: no meio da queda o azul fica ao lado de
    // dois azuis, e a trinca não pode fechar ali. Contar as combinações não
    // bastaria — um estouro no ar também daria uma trinca só. O que separa
    // os dois é **onde** a trinca fecha, e se o par do meio sobrou.
    const frame = 1 / 60;
    final scenario = scenarioCatalog.firstWhere(
      (s) => s.name == 'Passa reto pelo par',
    );
    final playfield = scenario.build();
    final grid = playfield.grid;
    final floor = playfield.geometry.floorRow;
    final passBy = RowIndex(floor.value - 4);
    Block? at(RowIndex row, int c) => grid.blockAt(row, Column(c));

    final cleared = <MatchCleared>[];
    for (var f = 0; f < 60 * 5 && cleared.isEmpty; f++) {
      cleared.addAll(playfield.update(frame).whereType<MatchCleared>());
    }

    expect(cleared, hasLength(1), reason: 'a trinca tem que fechar');
    expect(cleared.single.comboSize, 3);
    // No quadro em que fechou: o azul está no piso, piscando com o par de
    // baixo, e o par do meio continua parado, sem ninguém do lado.
    expect(at(floor, 0)?.color, BlockColor.blue);
    expect(at(floor, 0)?.state, BlockState.matched);
    expect(at(passBy, 0), isNull);
    for (final c in [1, 2]) {
      expect(at(passBy, c)?.state, BlockState.idle);
    }

    // E nada mais acontece depois: o par do meio desce um degrau quando o
    // de baixo sai, mas sem o terceiro azul não fecha nada.
    for (var f = 0; f < 60 * 5; f++) {
      cleared.addAll(playfield.update(frame).whereType<MatchCleared>());
    }
    expect(cleared, hasLength(1));
  });

  group('os cenários que sobem terminam sozinhos', () {
    const frame = 1 / 60;

    /// Roda sem jogador até a partida acabar, e devolve em quantos segundos.
    double? timeToGameOver(Playfield playfield, {int maxSeconds = 120}) {
      for (var f = 0; f < 60 * maxSeconds; f++) {
        playfield.update(frame);
        if (playfield.isOver) {
          return f / 60;
        }
      }
      return null;
    }

    test('sem a pilha segurada, ninguém joga para sempre', () {
      // Um cenário que sobe e nunca acaba seria um cenário que não dá para
      // usar para estudar a derrota — que é metade do catálogo hoje.
      for (final scenario in scenarioCatalog) {
        final playfield = scenario.build();
        if (playfield.risePaused) {
          continue;
        }
        expect(
          timeToGameOver(playfield),
          isNotNull,
          reason: 'o cenário "${scenario.name}" sobe mas nunca acaba',
        );
      }
    });

    test('a coluna sozinha derruba a partida sem encher o tabuleiro', () {
      // É o que o cenário existe para mostrar: perder é a linha que sai levar
      // **alguma** coisa, não o tabuleiro estar cheio.
      final scenario = scenarioCatalog.firstWhere(
        (s) => s.name == 'Coluna até o teto',
      );
      final playfield = scenario.build();

      final seconds = timeToGameOver(playfield, maxSeconds: 30);
      expect(seconds, isNotNull);
      expect(
        seconds,
        lessThan(10),
        reason: 'um cenário de derrota tem que ser rápido de exercitar',
      );

      final top = playfield.geometry.topRow;
      final occupied = playfield.geometry.columns
          .where((c) => playfield.grid.blockAt(top, c) != null)
          .length;
      expect(
        occupied,
        1,
        reason:
            'a linha que saiu levava uma célula só — e isso bastou para '
            'encerrar a partida',
      );
    });
  });
}
