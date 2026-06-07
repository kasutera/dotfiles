# shellcheck shell=bash
# shellcheck disable=SC1090,SC2154
# Change Ghostty colors while an ssh session is active.
# This uses OSC 10/11/12, so colors are per terminal surface and reset on exit.

[[ -o interactive ]] || return
[[ "${TERM_PROGRAM:l}" == ghostty || -n "${GHOSTTY_RESOURCES_DIR:-}" || "${TERM:-}" == xterm-ghostty ]] || return

typeset -g _GHOSTTY_SSH_COLORS_LOADED=1

# Hosts listed here are treated as local and keep the normal Ghostty theme.
# Put private hostnames in ~/.config/ghostty/ssh-colors.local.zsh.
typeset -ga GHOSTTY_SSH_LOCAL_HOSTS=(
  localhost
  127.0.0.1
  ::1
)

typeset -g GHOSTTY_SSH_REMOTE_BACKGROUND="#fdf6e3"
typeset -g GHOSTTY_SSH_REMOTE_FOREGROUND="#657b83"
typeset -g GHOSTTY_SSH_REMOTE_CURSOR="#657b83"

# Keep private host mappings out of this public repository.
_ghostty_ssh_colors_local="${GHOSTTY_SSH_COLORS_LOCAL:-${HOME}/.config/ghostty/ssh-colors.local.zsh}"
[[ -r "$_ghostty_ssh_colors_local" ]] && source "$_ghostty_ssh_colors_local"
unset _ghostty_ssh_colors_local

_ghostty_ssh_color_host() {
  local arg skip_next=0

  for arg in "$@"; do
    if (( skip_next )); then
      skip_next=0
      continue
    fi

    case "$arg" in
      --)
        continue
        ;;
      -[bcDEeFIiJLlmOopQRSWw])
        skip_next=1
        ;;
      -*)
        ;;
      *@*)
        print -r -- "${arg#*@}"
        return
        ;;
      *)
        print -r -- "$arg"
        return
        ;;
    esac
  done
}

_ghostty_ssh_is_local_host() {
  local host="$1"
  local short="${host%%.*}"
  local local_host local_short

  for local_host in "${GHOSTTY_SSH_LOCAL_HOSTS[@]}"; do
    local_short="${local_host%%.*}"
    [[ "$host" == "$local_host" || "$short" == "$local_short" ]] && return 0
  done

  return 1
}

_ghostty_ssh_color_apply() {
  local host="$1"
  local short="${host%%.*}"

  printf "\033]10;%s\033\\\\" "$GHOSTTY_SSH_REMOTE_FOREGROUND"
  printf "\033]11;%s\033\\\\" "$GHOSTTY_SSH_REMOTE_BACKGROUND"
  printf "\033]12;%s\033\\\\" "$GHOSTTY_SSH_REMOTE_CURSOR"
  printf "\033]2;ssh: %s\033\\\\" "$short"
}

_ghostty_ssh_color_reset() {
  printf "\033]110\033\\\\"
  printf "\033]111\033\\\\"
  printf "\033]112\033\\\\"
  printf "\033]2;%s\033\\\\" "${PWD/#$HOME/~}"
}

ghostty-ssh-color-test() {
  _ghostty_ssh_color_apply "${1:-example-remote}"
}

ghostty-ssh-color-reset() {
  _ghostty_ssh_color_reset
}

if (( ! $+functions[_ghostty_ssh_color_original_ssh] )); then
  if (( $+functions[ssh] )); then
    functions -c ssh _ghostty_ssh_color_original_ssh
  else
    _ghostty_ssh_color_original_ssh() {
      command ssh "$@"
    }
  fi
fi

ssh() {
  setopt local_options no_bg_nice

  local host ret
  local -a reapply_pids
  host="$(_ghostty_ssh_color_host "$@")"

  if [[ -n "$host" ]] && ! _ghostty_ssh_is_local_host "$host"; then
    _ghostty_ssh_color_apply "$host"
    if [[ -n "${GHOSTTY_SSH_COLOR_DEBUG:-}" ]]; then
      print -ru2 -- "ghostty-ssh-colors: apply host=${host}"
    fi
    local delay
    for delay in 0.15 0.5 1.5; do
      (
        sleep "$delay"
        _ghostty_ssh_color_apply "$host"
      ) &
      reapply_pids+=("$!")
    done
  elif [[ -n "$host" && -n "${GHOSTTY_SSH_COLOR_DEBUG:-}" ]]; then
    print -ru2 -- "ghostty-ssh-colors: keep default theme for local host=${host}"
  fi

  _ghostty_ssh_color_original_ssh "$@"
  ret=$?

  if (( ${#reapply_pids[@]} )); then
    local pid
    for pid in "${reapply_pids[@]}"; do
      kill "$pid" 2>/dev/null || true
    done
    _ghostty_ssh_color_reset
  fi

  return "$ret"
}
