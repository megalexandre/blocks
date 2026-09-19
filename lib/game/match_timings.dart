/// Os tempos da combinação: piscar, estourar, e o atraso entre um bloco e o
/// seguinte na cascata.
///
/// Value object porque **dois donos precisam dos mesmos números**: o sistema
/// de combinação, para conduzir a máquina de estados, e quem desenha, para
/// saber quanto do estouro já passou. O pintor importava o motor inteiro só
/// para ler uma constante dele — agora depende de um dado, não de um motor.
class MatchTimings {
  const MatchTimings({this.flash = 0.5, this.pop = 0.12, this.stagger = 0.05});

  static const MatchTimings standard = MatchTimings();

  /// Quanto tempo o grupo pisca antes de começar a estourar.
  final double flash;

  /// Quanto dura o estouro de um bloco.
  final double pop;

  /// Atraso entre um bloco e o seguinte, para o grupo sair em cascata.
  final double stagger;
}
