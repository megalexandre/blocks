import 'game_event.dart';

/// O placar.
///
/// Ouve o que aconteceu em vez de receber dois inteiros por posição: com
/// `register(int comboSize, int chainLevel)` ligado a um callback de mesma
/// forma, inverter os dois argumentos compilava e passava calado.
class Score {
  static const int pointsPerBlock = 10;

  int get total => _total;

  int _total = 0;

  void handle(GameEvent event) {
    if (event case MatchCleared(:final comboSize, :final chainLevel)) {
      _total += comboSize * pointsPerBlock * chainLevel;
    }
  }
}
