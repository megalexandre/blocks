# Corrige o DISPLAY quando a sessão gráfica do host mudou de número.
#
# O `containerEnv` do devcontainer.json copia o DISPLAY do host **uma vez**,
# quando o container é criado. Depois disso o valor fica congelado. Se o host
# reiniciar a sessão gráfica, ela volta com outro número (`:1` vira `:2`) e o
# container passa a falar com um display morto. O sintoma é seco:
#
#     Gtk-WARNING **: cannot open display: :1
#
# O conserto é possível porque `/tmp/.X11-unix` é montado como **diretório**,
# e não como arquivo: um socket novo criado no host aparece aqui dentro na
# hora, sem recriar nada. Só a variável é que está velha.
#
# A ordem de preferência é: o que já está valendo, o que o host anotou na
# última abertura (`initialize.sh`), e por último o maior socket que existir.
# Recriar o container continua sendo o conserto definitivo — isto aqui é o
# que salva a sessão em andamento.

_blocos_display_alive() {
  # Aceita ":2" e ":2.0"; o socket é /tmp/.X11-unix/X2 nos dois casos.
  [ -n "${1:-}" ] || return 1
  _blocos_n=${1#:}
  _blocos_n=${_blocos_n%%.*}
  [ -S "/tmp/.X11-unix/X${_blocos_n}" ]
}

if [ -d /tmp/.X11-unix ] && ! _blocos_display_alive "${DISPLAY:-}"; then
  _blocos_saved=$(cat /tmp/.host-x11/display 2>/dev/null || true)
  if _blocos_display_alive "$_blocos_saved"; then
    DISPLAY="$_blocos_saved"
    export DISPLAY
  else
    for _blocos_sock in /tmp/.X11-unix/X*; do
      [ -S "$_blocos_sock" ] || continue
      DISPLAY=":${_blocos_sock##*/X}"
      export DISPLAY
    done
  fi
  unset _blocos_saved _blocos_sock
fi

unset -f _blocos_display_alive
unset _blocos_n
