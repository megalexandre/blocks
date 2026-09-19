/// Uma coluna do tabuleiro.
///
/// Ao contrário de [RowIndex], **é estável**: a coluna 2 continua sendo a
/// coluna 2 depois de a pilha subir, e por isso pode ser guardada à vontade —
/// a animação da troca faz exatamente isso. A assimetria entre as duas é de
/// propósito e está nos nomes: linha tem *índice* (efêmero), coluna é *coisa*.
extension type const Column(int value) {
  Column get left => Column(value - 1);
  Column get right => Column(value + 1);

  /// Um passo na direção de [target].
  ///
  /// É aqui que mora "um gesto vale uma troca": não existe forma de andar
  /// duas casas de uma vez. Ir mais longe com o dedo não acumula trocas.
  Column towards(Column target) => target > this ? right : left;

  /// Andar várias colunas de uma vez, para quem varre a grade em passo livre.
  Column shifted(int columns) => Column(value + columns);

  int compareTo(Column other) => value.compareTo(other.value);

  bool operator <(Column other) => value < other.value;
  bool operator >(Column other) => value > other.value;
}
