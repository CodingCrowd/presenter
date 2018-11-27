# vim:ft=zsh ts=2 sw=2 sts=2
#
# Presenter theme for zsh. Using the command `present` it will remove the file path from display, then use `presentoff` to turn it back to normal.

### Segment drawing
# A few utility functions to make it easy and re-usable to draw segmented prompts

CURRENT_BG='NONE'
if [[ -z "$PRIMARY_FG" ]]; then
	PRIMARY_FG=black
fi

# PROMPT
if [ ! -n "${PRESENTER_PROMPT_CHAR+1}" ]; then
  PRESENTER_PROMPT_CHAR="\$"
fi
if [ ! -n "${PRESENTER_PROMPT_ROOT+1}" ]; then
  PRESENTER_PROMPT_ROOT=true
fi


# Characters
SEGMENT_SEPARATOR="\ue0b0"
BRANCH="\ue0a0"
DETACHED="\u27a6"
LIGHTNING="\u26a1"
GEAR="\u2699"
FIRE="🔥"
BEER="🍺"
BIN="🗑️"

# Begin a segment
# Takes two arguments, background and foreground. Both can be omitted,
# rendering default background/foreground.
prompt_segment() {
  local bg fg
  [[ -n $1 ]] && bg="%K{$1}" || bg="%k"
  [[ -n $2 ]] && fg="%F{$2}" || fg="%f"
  if [[ $CURRENT_BG != 'NONE' && $1 != $CURRENT_BG ]]; then
    print -n "%{$bg%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR%{$fg%}"
  else
    print -n "%{$bg%}%{$fg%}"
  fi
  CURRENT_BG=$1
  [[ -n $3 ]] && print -n $3
}

# End the prompt, closing any open segments
prompt_end() {
  if [[ -n $CURRENT_BG ]]; then
    print -n "%{%k%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR"
  else
    print -n "%{%k%}"
  fi
  print -n "%{%f%}"
  CURRENT_BG=''
}

### Prompt components
# Each component will draw itself, and hide itself if no information needs to be shown

# Context: user@hostname (who am I and where am I)
prompt_context() {
  local user=`whoami`

  if [[ "$user" != "$DEFAULT_USER" || -n "$SSH_CONNECTION" ]]; then
    prompt_segment $PRIMARY_FG default " %(!.%{%F{yellow}%}.)$user@%m "
  fi
}

# Git: branch/detached head, dirty status
prompt_git() {
  local color ref
  is_dirty() {
    test -n "$(git status --porcelain --ignore-submodules)"
  }
  ref="$vcs_info_msg_0_"
  if [[ -n "$ref" ]]; then
    if is_dirty; then
			color=yellow
      ref="${ref} $BIN "
    else
      color=green
      ref="${ref} "
    fi
    if [[ "${ref/.../}" == "$ref" ]]; then
      ref="$BRANCH $ref"
    else
      ref="$DETACHED ${ref/.../}"
    fi
    prompt_segment $color $PRIMARY_FG
    print -n " $ref"
  fi
}

# Dir: current working directory
prompt_dir() {
  prompt_segment blue $PRIMARY_FG ' %~ '
}

prompt_status() {
  local symbols
  symbols=()
  [[ $RETVAL -ne 0 ]] && symbols+="$FIRE"
	[[ $RETVAL -eq 0 ]] && symbols+="%{%F{red}%}$BEER"
  [[ $UID -eq 0 ]] && symbols+="%{%F{yellow}%}$LIGHTNING"
  [[ $(jobs -l | wc -l) -gt 0 ]] && symbols+="%{%F{cyan}%}$GEAR"

  [[ -n "$symbols" ]] && prompt_segment $PRIMARY_FG default " $symbols "
}

# Display current virtual environment
prompt_virtualenv() {
  if [[ -n $VIRTUAL_ENV ]]; then
    color=cyan
    prompt_segment $color $PRIMARY_FG
    print -Pn " $(basename $VIRTUAL_ENV) "
  fi
}

## Main prompt
prompt_agnoster_main() {
  RETVAL=$?
  CURRENT_BG='NONE'
	    if [[ -z $PRESENT ]]; then
				prompt_status
				prompt_context
				prompt_virtualenv
				prompt_dir
				prompt_git
				prompt_end
	    else
	        # note that I've had feedback that people seeing fire
	        # while I'm in demo mode is off-putting so I've disabled it
	        # here by default, but swap out the next two lines to enable it
	        # echo -n "%(?:💻 :🔥 )"
	        echo -n "💻 "
	        # if we're in the root of presentation, hide the path
	        if [[ ! $PWD == $PRESENT ]]; then
              $PRESENTER_PROMPT_CHAR = "0"
	            echo -n "%{$fg_bold[blue]%}%c%{$reset_color%} "
	        fi
	    fi
}

# Prompt Character
prompt_char() {
  local bt_prompt_char

  if [[ ${#PRESENTER_PROMPT_CHAR} -eq 1 ]] then
    bt_prompt_char="👉 "
  fi

  if [[ $PRESENTER_PROMPT_ROOT == true ]] then
    bt_prompt_char="%(!.%F{red}#.%F{green}${bt_prompt_char}%f)"
  fi

  echo -n $bt_prompt_char
}

prompt_agnoster_precmd() {
  vcs_info
  PROMPT='%{%f%b%k%}$(prompt_agnoster_main)
%{${fg_bold[default]}%}$(prompt_char) %{$reset_color%}'
}

prompt_agnoster_setup() {
  autoload -Uz add-zsh-hook
  autoload -Uz vcs_info

  prompt_opts=(cr subst percent)

  add-zsh-hook precmd prompt_agnoster_precmd

  zstyle ':vcs_info:*' enable git
  zstyle ':vcs_info:*' check-for-changes false
  zstyle ':vcs_info:git*' formats '%b'
  zstyle ':vcs_info:git*' actionformats '%b (%a)'
}

prompt_agnoster_setup "$@"
alias present='export PRESENT=$(pwd)'
alias presentoff='unset PRESENT'
