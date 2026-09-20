import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:blocos/dressing/game_over_painter.dart';

void main() {
  // O retângulo do botão é a única parte do painel que não é só pintura: é a
  // mesma conta que decide onde ele aparece e onde o toque vale. Se as duas
  // se separarem, o botão responde fora do lugar em que é visto — e isso não
  // aparece em nenhuma captura de tela.
  const board = Rect.fromLTWH(0, 0, 768, 1536);

  test('o botão fica centrado na horizontal', () {
    final button = GameOverPainter.buttonRect(board);

    expect(button.center.dx, board.center.dx);
  });

  test('fica abaixo do centro, onde o texto não alcança', () {
    final button = GameOverPainter.buttonRect(board);

    expect(button.top, greaterThan(board.center.dy));
  });

  test('cabe dentro do tabuleiro', () {
    final button = GameOverPainter.buttonRect(board);

    expect(board.contains(button.topLeft), isTrue);
    expect(board.contains(button.bottomRight), isTrue);
  });

  test('acompanha o tabuleiro em vez de usar medidas fixas', () {
    // Um tabuleiro de outro tamanho — outra geometria, ou outro aparelho —
    // não pode deixar o botão para trás, no lugar do tabuleiro antigo.
    const other = Rect.fromLTWH(100, 200, 400, 800);
    final button = GameOverPainter.buttonRect(other);

    expect(button.center.dx, other.center.dx);
    expect(button.center.dy, greaterThan(other.center.dy));
  });

  test('o centro do botão está dentro dele, e o canto do tabuleiro não', () {
    final button = GameOverPainter.buttonRect(board);

    expect(button.contains(button.center), isTrue);
    expect(
      button.contains(board.topLeft),
      isFalse,
      reason: 'tocar no canto do tabuleiro não pode reiniciar a partida',
    );
  });
}
