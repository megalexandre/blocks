#!/bin/sh
# Roda no host (initializeCommand) toda vez que o container vai subir, em
# qualquer máquina. Mount do tipo bind com origem inexistente faz o container
# nem subir; este script garante que as origens existam, mesmo numa máquina
# sem Claude ou sem tela.
set -eu
umask 077

# Conversas e memória do Claude. Numa máquina sem Claude fica só vazio.
mkdir -p "$HOME/.claude/projects"

# Sem servidor X (macOS sem XQuartz, por exemplo) o socket não existe.
[ -d /tmp/.X11-unix ] || mkdir -m 1777 /tmp/.X11-unix

# Pasta do socket de áudio. Com PulseAudio ou pipewire-pulse rodando ela já
# existe e isto não faz nada; sem eles, fica vazia e o jogo roda mudo. O
# caminho de reserva tem que bater com o valor padrão do mount no
# devcontainer.json.
mkdir -p "${XDG_RUNTIME_DIR:-/tmp/blocos-no-runtime-dir}/pulse"

# Cookie do X11, para a janela do app abrir na tela do host. É regravado a
# cada abertura porque muda a cada login. Fica numa pasta própria, montada
# inteira: um mount de arquivo prende o inode antigo, e o container
# continuaria vendo o cookie velho.
dir="$HOME/.cache/blocos-devcontainer"
mkdir -p "$dir"
rm -f "$dir/Xauthority"
touch "$dir/Xauthority"

# Qual display o host está usando agora.
#
# O `containerEnv` do devcontainer.json congela o DISPLAY no momento em que o
# container é criado. Quando a sessão gráfica do host reinicia, ela costuma
# voltar com outro número, e o container fica apontando para um display que
# não existe mais — a janela não abre e o erro é um `cannot open display`
# seco, que não diz o que houve.
#
# Este arquivo mora na mesma pasta do cookie, que é montada inteira e viva:
# o container lê daqui e se corrige sozinho, sem precisar ser recriado.
printf '%s' "${DISPLAY:-}" > "$dir/display"

# O `sed` troca a família de cada entrada por ffff (vale para qualquer host):
# o container tem outro hostname, e um cookie preso ao nome do host seria
# recusado lá dentro. Sem tela ou sem xauth o cookie fica vazio, e o container
# sobe do mesmo jeito, só sem janela.
if [ -n "${DISPLAY:-}" ] && command -v xauth >/dev/null 2>&1; then
  xauth nlist "$DISPLAY" 2>/dev/null \
    | sed 's/^..../ffff/' \
    | xauth -f "$dir/Xauthority" nmerge - 2>/dev/null || true
fi
