#!/usr/bin/env bash
########################################################################################################################
#                                           FILE: functions_jokes.sh                                                    #
#                                           DESCRIPTION: dev puns & jokes                                              #
########################################################################################################################

_NIXLPER_JOKES_FR=(
  "Que celui qui n'a mergé lui jette la première PR."
  "MR c'est c'qu'il y a d'plus beau.. MR c'est merger si haut.."
)

_NIXLPER_JOKES_EN=(
  "Monad monad monad! Must be funny, in the rich dev's world.."
)

function _i_joke_lang() {
  local lang="${NIXLPER_JOKE_LANG:-auto}"
  if [[ "${lang}" == "auto" ]]; then
    if [[ "${LANG:-}" == fr* ]]; then
      echo "fr"
    else
      echo "en"
    fi
  else
    echo "${lang}"
  fi
}

# @cmd-palette
# @description: Display a random dev pun or joke
# @category: Help
# @keybind: CTRL+X+K
# @alias: joke
function show_joke() {
  local lang
  lang=$(_i_joke_lang)

  local -a jokes
  if [[ "${lang}" == "fr" ]]; then
    jokes=("${_NIXLPER_JOKES_FR[@]}")
  else
    jokes=("${_NIXLPER_JOKES_EN[@]}")
  fi

  local count="${#jokes[@]}"
  if [[ ${count} -eq 0 ]]; then
    return
  fi

  local index=$(( RANDOM % count ))
  local joke="${jokes[${index}]}"

  local width=65
  local border
  border=$(printf '─%.0s' $(seq 1 ${width}))
  echo "╭─ 😄 Nixlper joke ${border}╮"
  printf "│  %-${width}s  │\n" "${joke}"
  echo "╰────────────────────${border}╯"
}
