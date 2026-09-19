/// A pilha subindo: a velocidade e o quanto já subiu.
///
/// Dono dos dois lados do movimento — a taxa e o acumulador. Deixar o
/// acumulador com quem chama faria a conta depender de duas classes: uma que
/// sabe a velocidade e outra que guarda o progresso, sem nada garantindo que
/// as duas concordem.
class StackRaiser {
  /// As taxas entram pelo construtor para um cenário de desenvolvimento poder
  /// acelerar a subida: verificar a pilha chegando no topo na velocidade
  /// normal é um minuto e meio de espera por execução.
  StackRaiser({
    this.baseRowsPerSecond = defaultBaseRowsPerSecond,
    this.boostRowsPerSecond = defaultBoostRowsPerSecond,
  });

  static const double defaultBaseRowsPerSecond = 1 / 8;
  static const double defaultBoostRowsPerSecond = 1;

  final double baseRowsPerSecond;
  final double boostRowsPerSecond;

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

  double get rowsPerSecond => (paused || frozen)
      ? 0
      : (boosting ? boostRowsPerSecond : baseRowsPerSecond);

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
  /// segundos na velocidade base; volta mais de 1 só se um quadro demorar
  /// demais, e aí as linhas não podem ser perdidas.
  int advance(double dt) {
    _offset += rowsPerSecond * dt;
    var completedRows = 0;
    while (_offset >= 1) {
      _offset -= 1;
      completedRows++;
    }
    return completedRows;
  }
}
