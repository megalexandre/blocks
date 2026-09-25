enum BlockColor { red, blue, green, yellow, purple, cyan }

enum BlockState { idle, matched, popping }

class Block {
  Block(this.color);

  final BlockColor color;
  BlockState state = BlockState.idle;
  double stateTime = 0;

  /// Quando **este** bloco começa a encolher, contado do início do estouro.
  /// É o que escalona a cascata da esquerda para a direita.
  double popDelay = 0;

  /// Quando ele sai da grade, contado do mesmo início.
  ///
  /// Vale para o **grupo inteiro**, não para este bloco: todos os blocos de
  /// uma combinação somem no mesmo instante, quando o último terminou de
  /// encolher. Removendo cada um no fim do próprio estouro, a célula da
  /// esquerda ficava livre um passo da cascata antes da célula à direita, e a
  /// pilha de cima desabava em escada em vez de cair inteira.
  ///
  /// Mora no bloco, e não numa lista de células guardada por quem estoura:
  /// uma lista de posições envelheceria na primeira subida da pilha, enquanto
  /// o bloco leva o próprio prazo junto aonde quer que a grade o mande.
  double clearAt = 0;

  double fallOffset = 0;

  /// Quantos passos de queda ainda faltam para ele **começar** a descer.
  ///
  /// A suspensão do original: bloco que perde o apoio não cai no mesmo
  /// instante, fica parado no ar um tempo curto e só então despenca. É ela
  /// que dá ao jogador a janela para deslizar um bloco por baixo — e é ela
  /// que segura a chain viva enquanto o buraco não fechou.
  ///
  /// Em passos, e não em segundos, porque a conta é exata: a suspensão gasta
  /// um passo de queda por passo de queda, e um contador de ponto flutuante
  /// zerado por subtrações sucessivas erraria o último passo para mais ou
  /// para menos. Quem traduz os segundos ajustáveis em passos é a
  /// `GravitySystem`, dona do relógio da queda.
  int hoverSteps = 0;

  /// Este bloco perdeu o apoio por causa de um estouro da cadeia em curso.
  ///
  /// É o que separa chain de combinação avulsa: o contador só sobe quando a
  /// combinação nova contém um bloco que a anterior derrubou. Uma trinca que
  /// o jogador fecha num canto qualquer enquanto a pilha ainda resolve é
  /// combinação nova, e não elo — no original ela vale chain 1.
  ///
  /// Mora no bloco, e não numa lista de células guardada por quem estoura,
  /// pelo mesmo motivo de [clearAt]: a marca acompanha o bloco pela queda e
  /// pela troca, enquanto uma lista de posições envelheceria na primeira
  /// subida da pilha. É também o que faz a chain sobreviver ao jogador
  /// deslizar o bloco marcado para o lugar onde ele vai fechar o próximo elo.
  bool chainLink = false;

  bool get isIdle => state == BlockState.idle;

  /// Parado **e no lugar**. [isIdle] sozinho diz só que o bloco não está
  /// piscando nem estourando — um bloco em pleno rastro de queda é `isIdle`,
  /// e era por isso que dava para trocá-lo no ar.
  ///
  /// Bloco suspenso também não se troca, como no original: ele ainda não caiu
  /// mas já não é seu. O que continua trocável é a **célula vazia embaixo
  /// dele** — é assim que se desliza um bloco por baixo do que está no ar.
  bool get isSettled => isIdle && fallOffset == 0 && hoverSteps == 0;

  void enter(BlockState next) {
    state = next;
    stateTime = 0;
  }
}
