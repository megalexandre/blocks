import 'dart:ui';

abstract final class Palette {
  static const background = Color(0xFFF3ECE3);
  static const playfield = Color(0xFFEAE0D2);
  static const playfieldBorder = Color(0xFFD9CBB8);
  /// A linha tracejada em repouso. Clara e translúcida porque agora ela fica
  /// sobre a paisagem, e o bege de antes sumia no verde.
  static const dangerLine = Color(0x99FFFFFF);

  /// A mesma linha quando a pilha alcança a folga do topo. Aí ela tem que
  /// chamar atenção, não combinar com o fundo.
  static const dangerLineAlert = Color(0xFFE5484D);

  /// Escurece o tabuleiro quando a partida acaba.
  static const gameOverVeil = Color(0x99101014);
  static const flash = Color(0xFFFFFFFF);

  static const textPrimary = Color(0xFF3A3348);

  /// Rótulos e texto de apoio: o mesmo tom do primário, mais leve.
  static const textSecondary = Color(0xFF8A8296);

  /// A chain. O tom escuro do amarelo dos blocos, para o número puxar o olho
  /// sem destoar da paleta das peças.
  static const chain = Color(0xFFC7AD6A);

  static const cardBackground = Color(0xFFFBF6EF);
  static const cardBorder = Color(0xFFD9CBB8);
}
