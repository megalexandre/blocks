import 'dart:math' as math;

/// A pilha subindo: a velocidade e o quanto já subiu.
///
/// Dono dos dois lados do movimento — a taxa e o acumulador. Deixar o
/// acumulador com quem chama faria a conta depender de duas classes: uma que
/// sabe a velocidade e outra que guarda o progresso, sem nada garantindo que
/// as duas concordem. Pelo mesmo motivo é dono do relógio da partida: a
/// velocidade depende dele, e um relógio contado em outro lugar poderia
/// discordar deste.
class StackRaiser {
  StackRaiser({
    this.baseRowsPerSecond = defaultBaseRowsPerSecond,
    this.doublingSeconds = defaultDoublingSeconds,
    this.maxGrowth = defaultMaxGrowth,
    this.boostMultiplier = defaultBoostMultiplier,
  });

  /// Velocidade do primeiro instante: uma linha a cada oito segundos.
  static const double defaultBaseRowsPerSecond = 1 / 8;

  /// De quanto em quanto tempo a velocidade dobra.
  static const double defaultDoublingSeconds = 90;

  /// Quantas vezes a velocidade inicial a pilha pode chegar a subir.
  ///
  /// Teto **relativo**, e não absoluto: um cenário de desenvolvimento que
  /// começa acelerado seria freado por um limite fixo, e o limite existe para
  /// a partida não virar impossível — não para desmentir quem escolheu a
  /// velocidade inicial.
  static const double defaultMaxGrowth = 8;

  /// Quanto o botão de acelerar multiplica a velocidade do momento.
  ///
  /// Multiplicador, e não uma taxa própria: com um valor absoluto, a subida
  /// natural acabaria alcançando o impulso com o passar da partida e o botão
  /// deixaria de fazer diferença justo quando mais importa.
  static const double defaultBoostMultiplier = 8;

  final double baseRowsPerSecond;
  final double doublingSeconds;
  final double maxGrowth;
  final double boostMultiplier;

  bool boosting = false;

  /// Congelada enquanto tem bloco caindo ou combinação resolvendo: a pilha
  /// para de subir enquanto o tabuleiro se assenta.
  bool frozen = false;

  /// Segurada de fora, e não pelo jogo.
  ///
  /// Separada de [frozen] de propósito: o `frozen` é recalculado a cada
  /// quadro por quem conduz o tabuleiro, então qualquer coisa escrita nele de
  /// fora dura um quadro e some. Este aqui ninguém reescreve — é o que deixa
  /// uma ferramenta de desenvolvimento segurar a pilha para examinar o
  /// tabuleiro parado.
  bool paused = false;

  /// Há quanto tempo a partida corre, em segundos.
  double get elapsed => _elapsed;

  double _elapsed = 0;

  /// Quantas vezes a velocidade inicial a pilha sobe agora, sem contar o
  /// impulso. Começa em 1 e cresce até [maxGrowth].
  double get growth =>
      math.min(math.pow(2, _elapsed / doublingSeconds).toDouble(), maxGrowth);

  /// A velocidade deste instante.
  ///
  /// Cresce sozinha com o tempo de partida: sem isso, sobreviver ao minuto
  /// dez é tão fácil quanto aos primeiros oito segundos, e o placar vira
  /// apenas uma medida de paciência.
  ///
  /// O congelamento **não** para o relógio, só a pilha. Uma combinação longa
  /// dá alívio no tabuleiro, não desconto na dificuldade.
  double get rowsPerSecond {
    if (paused || frozen) {
      return 0;
    }
    final natural = baseRowsPerSecond * growth;
    return boosting ? natural * boostMultiplier : natural;
  }

  /// Fração da linha atual que já subiu, de 0 a 1. É o deslocamento que quem
  /// desenha aplica na pilha inteira, e o que desempata em que linha o dedo
  /// tocou.
  double get offset => _offset;

  double _offset = 0;

  /// Faz a pilha subir por [dt] e devolve quantas **linhas inteiras** ela
  /// completou nesse passo — cada uma é uma linha que saiu pelo topo.
  ///
  /// Devolve a contagem em vez de mexer na grade porque subir é movimento, e
  /// a grade é de outra camada. Normalmente é 0, e vira 1 a cada oito
  /// segundos no começo da partida; volta mais de 1 só se um quadro demorar
  /// demais, e aí as linhas não podem ser perdidas.
  int advance(double dt) {
    // Segurada de fora, nada corre — nem o relógio. Uma ferramenta que
    // deixasse a partida parada por um minuto a devolveria acelerada, e
    // examinar um tabuleiro parado é justamente para o que ela serve.
    if (paused) {
      return 0;
    }
    _elapsed += dt;
    _offset += rowsPerSecond * dt;
    var completedRows = 0;
    while (_offset >= 1) {
      _offset -= 1;
      completedRows++;
    }
    return completedRows;
  }
}
