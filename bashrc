# shellcheck disable=SC1090
# shellcheck disable=SC1091

# Place for things like github tokens
if [ -f ~/.config/bash/tokens ]; then
  source ~/.config/bash/tokens
fi

# This part below is not really relevant in non interactive shells
if [ -n "$PS1" ]; then

if [ "$TERM" = "xterm-kitty" ] && [ -z "$SSH_CLIENT" ]; then
  source <(kitty + complete setup bash)
fi

# Set commandline editor to vim
# C-x C-e
export VISUAL=vim

# Use the trash can
if [ -n "$(command -v trash)" ]; then
  alias rm=trash
fi

# Helper for cleaning persistent SSH connections
if [ -n "$(command -v fzy)" ]; then
  alias ssh-kill="ps -x -ocommand | egrep '^ssh:.*\[mux\]' | cut -f 2 -d' ' | fzy | xargs -I\{\} -- ssh -S \{\} -O exit nop"
  alias ssh-updatekey='grep -oE "^[[a-z0-9.,:-]+" ~/.ssh/known_hosts | tr "," "\n" | tr -d '[' | fzy | xargs -I% sh -c "ssh-keygen -R % && ssh-keyscan -tecdsa % >> ~/.ssh/known_hosts"'
fi

# Use gpg-agent for ssh
test -f ~/.gpg-agent-info && . ~/.gpg-agent-info

# Colourise commands
if [ "$(command -v grc)" ]; then
  alias grc="grc -es --colour=auto"
  alias df='grc df'
  alias diff='grc diff'
  alias docker='grc docker'
  alias du='grc du'
  alias env='grc env'
  alias make='grc make'
  alias gcc='grc gcc'
  alias g++='grc g++'
  alias id='grc id'
  alias lsof='grc lsof'
  alias netstat='grc netstat'
  alias ping='grc ping'
  alias ping6='grc ping6'
  alias traceroute='grc traceroute'
  alias traceroute6='grc traceroute6'
  alias head='grc head'
  alias tail='grc tail'
  alias dig='grc dig'
  alias mount='grc mount'
  alias ps='grc ps'
  alias ifconfig='grc ifconfig'
fi
# shellcheck disable=SC2010
if ls --version 2>/dev/null | grep -q GNU; then
  alias ls='ls --color'
else
  alias ls='ls -G'
fi

if [ -n "$(command -v exa)" ]; then
  alias ls=exa
fi

if [ -n "$(command -v xdg-open)" ]; then
  alias open=xdg-open
fi

# Single window graphical vim
_graphical_vim_command=$(command -v gvim || command -v mvim)
if [ -n "$_graphical_vim_command" ]; then
gvim() {
  if [ -z "$(command $_graphical_vim_command --serverlist)" ]; then
    nohub command $_graphical_vim_command "$@" &
  else 
    command $_graphical_vim_command --remote-silent "$@"
  fi
}
alias mvim=gvim
fi

# Put brew sbin into PATH
if [ -d /usr/local/sbin ]; then
  export PATH="/usr/local/sbin:$PATH"
fi

# Make gettext availiable from brew
if [ -d /usr/local/opt/gettext/bin ]; then
  export PATH="/usr/local/opt/gettext/bin:$PATH"
fi

# Add ~/local/*/bin to PATH
# shellcheck disable=SC2155
export PATH=$(printf "%s:" ~/local/*/bin):$PATH

# Allow changing into some dirs directly
CDPATH=.:~/Projects:~/projects

# Case insensitive tab-completion
bind "set completion-ignore-case on"
bind "set show-all-if-ambiguous on"

# Show mathing parenthesis
bind "set blink-matching-paren on"

# Add some colour
bind "set colored-completion-prefix on"
bind "set colored-stats on"
bind "set visible-stats on"

# Don't wrap commandline
# bind "set horizontal-scroll-mode on"

# Allow completion in the middle of words
bind "set skip-completed-text on"

# Search using command line up up and down arrow
bind '"\e[A": history-search-backward'
bind '"\e[B": history-search-forward'

# ctrl + arrow keys to move words
bind '"\e[1;2C":forward-word'
bind '"\e[1;2D":backward-word'

# vi mode
# set -o vi
# bind "set show-mode-in-prompt on"
# bind "set vi-ins-mode-string"
# bind "set vi-cmd-mode-string +"

# Setup bash history
HISTCONTROL=ignoreboth
HISTSIZE=-1
HISTTIMEFORMAT='%F %T: '
shopt -s histappend
shopt -s cmdhist

# Enable extended globs
shopt -s extglob

# List running background jobs before exiting
shopt -s checkjobs

# Show dot-files when tab completing
shopt -s dotglob

# expand ** and **/
shopt -s globstar

# Go stuff
if [ -d ~/projects/go ]; then
  export GOPATH=~/projects/go
fi
if [ -d ~/Private/projects/go ]; then
  export GOPATH=~/Private/projects/go
fi
if [ -n "$GOPATH" ]; then
  export PATH=$PATH:$GOPATH/bin
fi

# Setup nvm
if [ -s /usr/share/nvm/init-nvm.sh ]; then
  source /usr/share/nvm/init-nvm.sh
fi

# Setup rustup
if [ -s ~/.cargo/env ]; then
  source ~/.cargo/env
fi

# Setup rvm
if [ -s ~/.rvm/scripts/rvm ]; then
  export PATH="$HOME/.rvm/bin:$PATH"
  source ~/.rvm/scripts/rvm
  source ~/.rvm/scripts/completion
fi

# Enable bash_completion
[ -f /usr/local/etc/bash_completion ] && . /usr/local/etc/bash_completion
[ -f /usr/share/bash-completion/bash_completion/bash_completion ] && . /usr/share/bash-completion/bash_completion
[ -f /etc/bash_completion ] && . /etc/bash_completion
[ -f /usr/share/doc/pkgfile/command-not-found.bash ] && . /usr/share/doc/pkgfile/command-not-found.bash

# Load local bash-completions
if [ -d ~/local/bash_completion/bash_completion.d/ ]; then
  for bc in ~/local/bash_completion/bash_completion.d/*; do
    source "$bc"
  done
fi

# Prompt
function __prompt_cmd
{
  local exit_status=$?
  local prompt='λ'
  local blue="\\[\\e[34m\\]"
  local red="\\[\\e[31m\\]"
  local green="\\[\\e[32m\\]"
  local yellow="\\[\\e[33m\\]"
  local normal="\\[\\e[m\\]"

  local status_color
  if [ $exit_status != 0 ]; then
    status_color="$red"
  else
    status_color="$blue"
  fi

  PS1="${status_color}╭${normal}[$yellow\\D{%T}$normal]"
  if [ -n "$SSH_CLIENT" ]; then
    PS1+="$red \\u@\\h (remote)$normal"
  else
    PS1+=" \\u@\\h"
  fi
  PS1+="$blue \\w$normal\\n"

  local let_line

  # git based on https://github.com/jimeh/git-aware-prompt/
  local branch
  if branch=$(git rev-parse --abbrev-ref HEAD 2> /dev/null); then
    if [ "$branch" = "HEAD" ]; then
      branch='detached*'
    fi
    let_line+="${yellow}${branch}"
    # shellcheck disable=SC2155
    local stash=$(git stash list 2>/dev/null)
    if [ -n "$stash" ]; then
      let_line+="^"
    fi
    # shellcheck disable=SC2155
    local status=$(git status --porcelain -b --ahead-behind 2> /dev/null)
    if [ "$(wc -l <<< "$status")" -gt 1 ]; then
      let_line+="*"
    fi
    let_line+=" $(head -n1 <<< "$status" | cut -d ' ' -f 3-)"

    let_line+="$normal "
  fi

  # Python virtualenv
  if [ -n "$VIRTUAL_ENV" ]; then
    let_line+="$green${VIRTUAL_ENV##*/}$normal "
  fi

  # RVM
  if [ -n "$(command -v rvm-prompt)" ]; then
    if [ -n "$(rvm-prompt g)" ]; then
      let_line+="$red$(rvm-prompt)$normal "
    fi
  fi

  # GOPATH
  if [ "${PWD##$GOPATH}" != "${PWD}" ]; then
    let_line+="${blue}Good to Go!$normal "
  fi

  if [ -n "$let_line" ]; then
    PS1+="${status_color}│$normal $let_line"
    PS1+="\\n"
  fi

  PS1+="${status_color}╰${normal} ${prompt} "

  # Save history continuously
  history -a
}

PROMPT_COMMAND=__prompt_cmd
# Don't have python virtual environment set prompt
export VIRTUAL_ENV_DISABLE_PROMPT=1

if [ -n "$(command -v fortune)" ]; then
  printf '\033[0;35m'
  fortune -e -s
  printf '\033[0m'
fi
fi
