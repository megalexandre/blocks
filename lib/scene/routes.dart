/// Os nomes das rotas da cena.
///
/// Constantes num lugar só porque o `RouterComponent` do Flame roteia por
/// `String`: com o literal solto, um erro de digitação em
/// `pushReplacementNamed` só aparece como uma tela que não troca.
abstract final class Routes {
  static const String loading = 'carregando';
  static const String menu = 'menu';
  static const String match = 'partida';
}
