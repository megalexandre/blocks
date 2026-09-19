/// Posição **visual** de uma linha: 0 é o topo da tela.
///
/// O significado muda a cada subida da pilha, então nunca deve ser guardada
/// entre quadros — quem precisa apontar para uma linha ao longo do tempo
/// guarda a `BoardRow` e pergunta a posição na hora de usar.
///
/// Extension type porque em tempo de execução **é um `int`**: uma
/// `List<RowIndex>` é uma `List<int>`, e não custa uma alocação sequer. O que
/// se ganha é o compilador recusando passar uma coluna onde se espera uma
/// linha — o erro que `atIndex(index, col)` convidava em toda a base.
///
/// Sem `implements Object`, de propósito. Os membros de `Object` continuam
/// disponíveis (`==` e `hashCode` caem no `int` de baixo, que é o que faz
/// `indexOf` e `Set` funcionarem), mas o tipo **não** vira atribuível a
/// `Object` — e com isso fecha mais uma via de uma linha virar inteiro cru
/// sem ninguém notar.
///
/// Não tem `operator +`. Somar 1 a uma linha só quer dizer uma coisa — "a de
/// baixo" — e [below] diz isso sem exigir lembrar que 0 é o topo. A
/// alternativa rejeitada, aritmética livre, devolveria o mesmo convite ao
/// erro com outra roupa.
extension type const RowIndex(int value) {
  /// A linha imediatamente mais perto do piso.
  RowIndex get below => RowIndex(value + 1);

  /// A linha imediatamente mais perto do topo.
  RowIndex get above => RowIndex(value - 1);

  /// Andar várias linhas de uma vez. Existe para quem varre a grade em passo
  /// livre — a montagem da pilha de abertura e a busca de sequências — e é a
  /// única porta para isso: no resto do código o movimento é [above]/[below].
  RowIndex shifted(int rows) => RowIndex(value + rows);

  int compareTo(RowIndex other) => value.compareTo(other.value);

  bool operator <(RowIndex other) => value < other.value;
  bool operator >(RowIndex other) => value > other.value;
  bool operator <=(RowIndex other) => value <= other.value;
  bool operator >=(RowIndex other) => value >= other.value;
}
