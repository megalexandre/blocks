import 'dart:ui';

/// As cores.
///
/// A base saiu do bege e foi para o navy do pacote Treasure Hunters: `#33323D`
/// é a cor de contorno com que todo tile do pacote foi desenhado, e é sobre
/// ela que a moldura dourada e a fonte laranja foram feitas para viver. Contra
/// o bege de antes, o contorno escuro do pixel art ficava duro e a fonte
/// perdia contraste.
///
/// A rampa completa do pacote, para quem precisar de um tom novo:
/// `#33323D` `#833F4C` `#985252` `#A04F45` `#B77357` `#AE7764` `#DAAB76`
/// `#EBD9A1`.
abstract final class Palette {
  /// Tudo que não é o vão do tabuleiro. Vale também para o letterbox: o
  /// `GameScene.backgroundColor()` é transparente e deixa ver o `Scaffold`.
  static const background = Color(0xFF33323D);

  /// Um degrau abaixo da base, para painel encostado nela não sumir.
  static const surface = Color(0xFF26252E);

  /// Sobrou como **véu**, não como fundo: escurece a linha que ainda está
  /// entrando por baixo e a animação de troca. Era o bege do tabuleiro, quando
  /// o tabuleiro tinha fundo chapado; hoje quem está atrás dos blocos é a
  /// paisagem, e clarear em cima dela lavava a cor da peça.
  static const playfield = Color(0xFF1C1B22);

  static const playfieldBorder = Color(0xFF5A4A44);

  /// A linha tracejada em repouso. Clara e translúcida porque ela fica sobre a
  /// paisagem, e o bege de antes sumia no verde.
  static const dangerLine = Color(0x99FFFFFF);

  /// A mesma linha quando a pilha alcança a folga do topo. Aí ela tem que
  /// chamar atenção, não combinar com o fundo.
  static const dangerLineAlert = Color(0xFFE5484D);

  /// Escurece o tabuleiro quando a partida acaba.
  static const gameOverVeil = Color(0xB3101014);
  static const flash = Color(0xFFFFFFFF);

  /// O creme do pacote. É a cor de todo texto que não é manchete — a fonte
  /// pequena nasce escura e é tingida com ele.
  static const textPrimary = Color(0xFFEBD9A1);

  /// Rótulos e texto de apoio: o mesmo creme, rebaixado para não competir com
  /// o número que ele nomeia.
  static const textSecondary = Color(0xFFAE9B7E);

  /// A chain. O ouro do pacote, que é também o tom do quadro dourado.
  static const chain = Color(0xFFDAAB76);

  /// O chanfro do rebaixo cavado na moldura: escuro em cima e à esquerda,
  /// claro embaixo e à direita. É essa inversão que faz ler como afundado —
  /// trocada, leria como botão saltado.
  static const insetShadow = Color(0xFF2A2028);
  static const insetLight = Color(0xFFC99A6E);
  static const insetFill = Color(0xFF5C3B41);

  static const cardBackground = Color(0xFF3D3B47);
  static const cardBorder = Color(0xFF55525F);
}
