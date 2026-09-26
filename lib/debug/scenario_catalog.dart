import '../game/board_script.dart';
import 'scenario.dart';

/// Os cenários do menu de desenvolvimento.
///
/// Cada um é uma situação que custa caro alcançar jogando. O desenho é
/// ancorado no piso, então quase todos cabem em poucas linhas — veja
/// [BoardScript] para o formato.
const List<Scenario> scenarioCatalog = [
  Scenario(
    name: 'Partida normal',
    purpose: 'O jogo como ele é. Pilha de abertura sorteada a cada entrada.',
    seed: 0,
  ),
  Scenario(
    name: 'Partida com semente fixa',
    purpose:
        'Mesma partida toda vez. Para perseguir um bug que dependa do '
        'sorteio.',
    seed: 20260919,
  ),

  Scenario(
    name: 'Chain 2',
    purpose:
        'O trio vermelho estoura, os azuis perdem apoio, caem e fecham o '
        'segundo trio. A chain tem que marcar 2, não 1.',
    risePaused: true,
    board: BoardScript('''
      .BB...
      RRRB..
    '''),
  ),
  Scenario(
    name: 'Chain 3',
    purpose:
        'Duas quedas encadeadas. A chain tem que chegar a 3 antes da pilha '
        'assentar.',
    risePaused: true,
    // Os três elos caem em colunas diferentes, e é isso que os separa no
    // tempo. O desenho anterior soltava a segunda e a terceira trinca no
    // mesmo passo de queda — as duas fechavam no mesmo quadro, viravam um
    // grupo só de seis blocos, e a chain parava em 2 mostrando combo 6.
    //
    // Aqui: os vermelhos saem e derrubam os azuis das colunas 1 e 2, que
    // fecham o trio azul com o azul parado da coluna 3 (elo 2). Só então o
    // verde que estava por cima desse azul perde o apoio, desce sozinho e
    // encosta nos dois verdes que nunca saíram do lugar (elo 3).
    board: BoardScript('''
      .BBG..
      RRRBGG
    '''),
  ),
  Scenario(
    name: 'Arrastar a linha inteira',
    purpose:
        'Um arraste só carrega o bloco de ponta a ponta, em vez de trocar uma '
        'casa e parar. Seis cores distintas em duas linhas: nada combina, '
        'então dá para ver a linha se reorganizando enquanto o dedo anda.',
    risePaused: true,
    continuousDrag: true,
    board: BoardScript('''
      YCPRGB
      RGBYCP
    '''),
  ),
  Scenario(
    name: 'Combo 5 em L',
    purpose:
        'Trio horizontal cruzando com trio vertical: uma combinação só, de '
        'cinco blocos. O canto não pode ser contado duas vezes.',
    risePaused: true,
    board: BoardScript('''
      Y.....
      Y.....
      YYY...
    '''),
  ),
  Scenario(
    name: 'Cascata longa',
    purpose:
        'Seis blocos saindo juntos. O estouro sai em cascata da esquerda '
        'para a direita, mas a pilha de cima tem que descer INTEIRA, não em '
        'escada.',
    risePaused: true,
    board: BoardScript('''
      BGYPBG
      RRRRRR
    '''),
  ),
  Scenario(
    name: 'Queda alta',
    purpose:
        'Um bloco solto no alto caindo até o piso. Para ver o rastro '
        'interpolar em vez de pular de linha em linha.',
    risePaused: true,
    // Começa na linha 1, e não na 0: a linha do topo é o teto, e um bloco
    // ali encerra a partida antes de ele chegar a cair.
    board: BoardScript('''
      B.....
      ......
      ......
      ......
      ......
      ......
      ......
      ......
      ......
      ......
      .YGPYG
    '''),
  ),
  Scenario(
    name: 'Passa reto pelo par',
    purpose:
        'Um azul cai rente a um par de azuis e passa por ele sem estourar: '
        'no ar não se combina. Só fecha a trinca com o par do piso, quando '
        'pousa.',
    risePaused: true,
    // O par do meio fica na linha por onde o azul passa, colado na coluna
    // dele. Se o detector aceitasse bloco sem apoio, a trinca fecharia ali,
    // no meio da queda, e o azul nunca chegaria ao piso.
    board: BoardScript('''
      B.....
      ......
      .BB...
      .GY...
      .YG...
      .GY...
      .BB...
    '''),
  ),
  Scenario(
    name: 'Troca no ar',
    purpose:
        'Um bloco em pleno rastro de queda. Tentar trocá-lo com o vizinho: '
        'tem que ser recusado, porque ele não está assentado.',
    risePaused: true,
    board: BoardScript('''
      B.....
      ......
      ......
      .YGPYG
    '''),
  ),
  Scenario(
    name: 'Pilha na linha de perigo',
    purpose:
        'Tabuleiro quase cheio, subindo rápido. Prepara o terreno para a '
        'derrota, que o jogo ainda não tem.',
    riseRowsPerSecond: 1,
    board: BoardScript('''
      BGYPBG
      GYPBGY
      YPBGYP
      PBGYPB
      BGYPBG
      GYPBGY
      YPBGYP
      PBGYPB
      BGYPBG
      GYPBGY
    '''),
  ),
  Scenario(
    name: 'Coluna até o teto',
    purpose:
        'Uma torre solitária subindo. Quando o bloco mais alto for empurrado '
        'para fora pelo topo, a partida acaba — basta uma célula ocupada na '
        'linha que sai, não o tabuleiro cheio.',
    riseRowsPerSecond: 1,
    board: BoardScript('''
      ......
      ......
      ..R...
      ..G...
      ..B...
      ..R...
      ..G...
      ..B...
      ..R...
      ..G...
      ..B...
      ..R...
    '''),
  ),
  Scenario(
    name: 'As seis cores',
    purpose:
        'Uma coluna de cada cor, lado a lado. Serve para conferir se ciano e '
        'azul se distinguem de relance, e se todas leem bem sobre a '
        'paisagem.',
    risePaused: true,
    board: BoardScript('''
      RGCPYB
      RGCPYB
    '''),
  ),
  Scenario(
    name: 'Tabuleiro vazio',
    purpose:
        'Só o piso. Para montar uma situação à mão, arrastando blocos da '
        'linha que entra por baixo.',
    risePaused: true,
    board: BoardScript('......'),
  ),
];
