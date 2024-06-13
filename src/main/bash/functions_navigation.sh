#!/usr/bin/env bash
########################################################################################################################
#                                           FILE: navigation.sh                                                        #
#                                           DESCRIPTION: functions related to navigation                               #
########################################################################################################################
# Make the navigation easier, calling this navigate function display the following output depending on the display mode
#
# Tree mode
# ---------------------------------------------------------------------------------------------------------------
# ..  ↑ CTRL + X THEN U
# ├── first item (→ or ↓) SHORTCUT_COMMAND
# ├── ..
# ├── item N (→ or ↓) SHORTCUT_COMMAND
# ├── ..
# └── last item (→ or ↓) SHORTCUT_COMMAND
#
# HINT 1: use alias nNUMBER to navigate, alias vNUMBER to open a file (FILES AND FOLDERS/ALIAS MODE)
# HINT 2: use CTRL + X, NUMBER to navigate (FOLDERS ONLY/BINDING MODE)
# -> Currently in /appli/install
#---------------------------------------------------------------------------------------------------------------
#
# Flat mode
# ---------------------------------------------------------------------------------------------------------------
# Open..
# vim file1 # (v1)
# vim file2 # (v2)
# ..
# vim fileN # (vN)
# ----
# Go to subfolder
# navigate absolute_path_1 # (n1)
# navigate absolute_path_2 # (n2)
# ..
# navigate absolute_path_n # (nN)
# ----
# Go to parent folder..
# cd parent_folder # CTRL + X THEN U
# ---------------------------------------------------------------------------------------------------------------
# HINT: double click then right click for copy/paste"
# HINT: use alias nNUMBER to navigate, alias vNUMBER to open a file"
# -> Currently in current_folder"
# ---------------------------------------------------------------------------------------------------------------
########################################################################################################################
function navigate() {
  if [[ "${NIXLPER_NAVIGATE_MODE}" == "tree" ]]; then
    _i_navigate_tree "$@"
  else
    _i_navigate_flat "$@"
  fi
}

function _i_navigate_tree() {
  if [[ $# -ne 0 ]]; then
    cd "$1" || return 1
  fi
  echo ""
  echo "---------------------------------------------------------------------------------------------------------------"
  echo "..  ↑ CTRL + X THEN U"
  local -r colored_tree_output=$(tree -L 1 -C | tail -n +2 | head -n -2)
  IFS=$'\n'
  local folder_increment=1
  local file_increment=1
  local uncolored_line
  local current_item
  for i in ${colored_tree_output}; do
    uncolored_line=$(echo $i | sed 's,\x1B\[[0-9;]*[a-zA-Z],,g')
    current_item=$(echo "${uncolored_line}" | cut -d' ' -f2)
    if [[ -f "${current_item}" ]]; then
      # shellcheck disable=SC2139
      alias v${file_increment}="vim $current_item"
      echo "$i → v${file_increment}"
      ((file_increment++))
    elif [[ -d "${current_item}" ]]; then
      # shellcheck disable=SC2139
      alias n${folder_increment}="navigate $current_item"
      if [[ ${increment} -lt 10 ]]; then
        bind -x '"\C-x'${folder_increment}'": navigate '${current_item}''
        echo "$i ↓ n${folder_increment}/CTRL + X, ${folder_increment}"
      else
        echo "$i ↓ n${folder_increment}"
      fi
      ((folder_increment++))
    else
      echo "$i"
    fi
  done
  echo ""
  echo "HINT 1: use alias nNUMBER to navigate, alias vNUMBER to open a file (FILES AND FOLDERS/ALIAS MODE)"
  echo "HINT 2: use CTRL + X, NUMBER to navigate (FOLDERS ONLY/BINDING MODE)"
  echo "-> Currently in $(pwd)"
  echo "---------------------------------------------------------------------------------------------------------------"
  echo ""
}

function _i_navigate_flat() {
  if [[ $# -ne 0 ]]; then
    cd "$1" || return 1
  fi

  local -r files_output=$(find . -mindepth 1 -maxdepth 1 -type f)
  local -r folders_output=$(find . -mindepth 1 -maxdepth 1 -type d)

  echo ""
  echo "---------------------------------------------------------------------------------------------------------------"
  echo "Open.."
  local increment=1
  for i in ${files_output}; do
    # shellcheck disable=SC2139
    alias v${increment}="vim $i"
    echo "vim ${i:2} # (v${increment})"
    ((increment++))
  done

  echo "----"
  echo "Go to subfolder.."
  increment=1
  for i in ${folders_output}; do
    # shellcheck disable=SC2139
    alias n${increment}="navigate $i"
    if [[ ${increment} -lt 10 ]]; then
      bind -x '"\C-x'${increment}'": navigate '${i}''
      echo "navigate $(pwd)/${i:2} # (n${increment} / CTRL + X, ${increment})"
    else
      echo "navigate $(pwd)/${i:2} # (n${increment})"
    fi
    ((increment++))
  done

  echo "----"
  echo "Go to parent folder.."
  # shellcheck disable=SC2046
  echo "cd $(dirname $(pwd)) # CTRL + X THEN U"

  echo "---------------------------------------------------------------------------------------------------------------"
  echo "HINT 1: double click then right click for copy/paste (FILES AND FOLDERS/MOUSE MODE)"
  echo "HINT 2: use alias nNUMBER to navigate, alias vNUMBER to open a file (FILES AND FOLDERS/ALIAS MODE)"
  echo "HINT 3: use CTRL + X, NUMBER to navigate (FOLDERS ONLY/BINDING MODE)"
  echo "-> Currently in $(pwd)"
  echo "---------------------------------------------------------------------------------------------------------------"
  echo ""
}

# Execute "find . -iname "*PATTERN"" then display results in "navigate" style
function _find_and_navigate() {
  if [[ $# -eq 0 ]]; then
    _i_log_as_error "Missing pattern for find_and_navigate"
    return 1
  elif [[ -z $1 ]]; then
    _i_log_as_error "Pattern cannot be empty for for find_and_navigate"
    return 1
  else
    local -r find_results=$(find . -iname "*$**")
    local item_increment=1
    if [[ -n ${find_results} ]]; then
      local path_depth
      local tree_chars
      echo ".."
      for i in ${find_results}; do
        tree_chars="├──"
        path_depth=$(echo "$i" | grep -o "/" | wc -l)
        for ((j=1; j <= path_depth; j++))  ; do
          tree_chars="${tree_chars}─"
        done
        if [[ -f $i ]]; then
          # shellcheck disable=SC2139
          alias v${item_increment}="vim $i"
          echo "${tree_chars} ${i:2} → v${item_increment}"
        elif [[ -d $i ]]; then
          # shellcheck disable=SC2139
          alias n${item_increment}="cd ${i} && navigate"
          echo "${tree_chars} ${i:2} ↓ n${item_increment}"
        fi
        ((item_increment++))
      done
      echo ".."
    else
      echo "No match"
    fi
  fi
}
