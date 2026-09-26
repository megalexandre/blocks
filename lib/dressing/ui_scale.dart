/// Em quantas vezes cada pixel de arte do pacote é ampliado.
///
/// **Sempre inteiro.** O pacote é pixel art: em escala fracionária umas
/// fileiras de pixel saem com uma largura e outras com outra, e o traço de 1px
/// que desenha todo contorno vira um traço irregular. Em escala inteira o pixel
/// continua quadrado.
///
/// A regra que decide o `FilterQuality` de cada desenhador **não é sobre a
/// arte, é sobre se a coisa se mexe em fração de pixel**:
///
/// * anda em fração de pixel e é arte suave — os blocos, que sobem ~0,1px por
///   quadro — pede `medium`, porque o mipmap pré-média a origem e tira a
///   dependência da fase sub-pixel. É o que `BlockSprites` já faz, e não muda.
/// * fica parado — moldura, HUD, menu, botões, texto — pede `none`. Parado não
///   cintila, e `none` é o que preserva a aresta dura do pixel art.
/// * é pixel art **e** se mexe — só a porta, deslizando — pede `none` mais o
///   arredondamento para pixel de tela inteiro a cada quadro. É a mesma
///   resposta que `BoardViewport.topOf` já dá para o mesmo problema.
abstract final class UiScale {
  /// Painéis de 32px. 32 × 4 = 128, que é exatamente a célula do tabuleiro —
  /// e é isso que faz a moldura e a porta fecharem em tile inteiro sobre um
  /// vão de 768×1536, sem meio tijolo na ponta.
  static const int panel = 4;

  /// Lado da borda da moldura, em unidades do canvas.
  static const double frameBorder = 32.0 * panel;

  /// Painel de botão. Menor que o da moldura porque o quadro de um botão não
  /// é o quadro de uma janela: em escala 4 os dois cantos já somam 256, e um
  /// botão de 210 de altura não caberia dentro do próprio contorno — foi
  /// exatamente o que o `assert` do `NineSlice` apontou na primeira vez que
  /// este menu subiu.
  static const int button = 2;

  /// A fonte grande no nome do jogo, que é a maior coisa escrita em tela.
  static const int title = 12;

  /// Fonte grande em manchete — placar, rótulo de botão.
  static const int headline = 7;

  /// Fonte pequena em rótulo, acima do número que ela nomeia. Bem menor que a
  /// manchete de propósito: em escalas parecidas o rótulo compete com o
  /// número, e quem lê o placar de relance lê "PONTOS" antes de ler quantos.
  static const int label = 4;

  /// A palavra SUBIR, deitada letra a letra dentro do rebaixo. Maior que o
  /// rótulo do placar porque ali ela é a única coisa escrita, e a coluna é
  /// estreita o bastante para uma letra pequena sumir.
  static const int boostLabel = 6;

  /// Quanto a porta invade o batente. Só o bastante para a borda dela ficar
  /// escondida sob a parte opaca da moldura — a face externa das arestas do
  /// painel tem 20 unidades transparentes, então qualquer coisa entre 20 e a
  /// borda inteira serve. Invadindo a borda toda, a porta fechada tapava a
  /// madeira inteira e só sobrava o friso de metal.
  static const double doorOverlap = 24;

  /// O número do selo do multiplicador, na fonte pequena, saltando sobre o
  /// tabuleiro. Escolhido pela célula: em 8, "×2" dá 88 unidades de largura e
  /// 48 de altura, que com a folga do selo fecha 120×80 dentro de uma célula
  /// de 128 — grande o bastante para se ler de relance, pequeno o bastante
  /// para não tapar a jogada.
  static const int chainBadge = 8;

  /// Ícones de 8×6.
  static const int icon = 7;
}
