# {{{Settings
# zmodload zsh/zprof
# {{{env
set -o monitor
set +o nonotify
umask 077
setopt hist_save_no_dups hist_ignore_dups       # eliminate duplicate entries in history
setopt correctall                               # enable auto correction
setopt autopushd pushdignoredups                # auto push dir into stack and and don’t duplicate them
# }}}
# {{{prompt
autoload -U promptinit
promptinit
# }}}
# {{{completion
zcomp_init () {
    # Auto load
    autoload -U +X compinit && compinit
    autoload -U +X bashcompinit && bashcompinit

    # Set options
    setopt MENU_COMPLETE       # press <Tab> one time to select item
    setopt COMPLETEALIASES     # complete alias
    setopt COMPLETE_IN_WORD    # Complete from both ends of a word.
    setopt ALWAYS_TO_END       # Move cursor to the end of a completed word.
    setopt PATH_DIRS           # Perform path search even on command names with slashes.
    setopt AUTO_MENU           # Show completion menu on a successive tab press.
    setopt AUTO_LIST           # Automatically list choices on ambiguous completion.
    setopt AUTO_PARAM_SLASH    # If completed parameter is a directory, add a trailing slash.
    setopt EXTENDED_GLOB       # Needed for file modification glob modifiers with compinit
    unsetopt FLOW_CONTROL      # Disable start/stop characters in shell editor.

    # Use caching to make completion for commands such as dpkg and apt usable.
    zstyle ':completion::complete:*' use-cache on
    zstyle ':completion::complete:*' cache-path "${ZDOTDIR:-$HOME}/.cache/.zcompcache"
    
    # Case-insensitive (all), partial-word, and then substring completion.
    if zstyle -t ':prezto:module:completion:*' case-sensitive; then
      zstyle ':completion:*' matcher-list 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
      setopt CASE_GLOB
    else
      zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
      unsetopt CASE_GLOB
    fi
    
    # Group matches and describe.
    zstyle ':completion:*:*:*:*:*' menu select
    zstyle ':completion:*:matches' group 'yes'
    zstyle ':completion:*:options' description 'yes'
    zstyle ':completion:*:options' auto-description '%d'
    zstyle ':completion:*:corrections' format ' %F{green}-- %d (errors: %e) --%f'
    zstyle ':completion:*:descriptions' format ' %F{yellow}-- %d --%f'
    zstyle ':completion:*:messages' format ' %F{purple} -- %d --%f'
    zstyle ':completion:*:warnings' format ' %F{red}-- no matches found --%f'
    zstyle ':completion:*:default' list-prompt '%S%M matches%s'
    zstyle ':completion:*' format ' %F{yellow}-- %d --%f'
    zstyle ':completion:*' group-name ''
    zstyle ':completion:*' verbose yes
    
    # Fuzzy match mistyped completions.
    zstyle ':completion:*' completer _complete _match _approximate
    zstyle ':completion:*:match:*' original only
    zstyle ':completion:*:approximate:*' max-errors 1 numeric
    
    # Increase the number of errors based on the length of the typed word. But make
    # sure to cap (at 7) the max-errors to avoid hanging.
    zstyle -e ':completion:*:approximate:*' max-errors 'reply=($((($#PREFIX+$#SUFFIX)/3>7?7:($#PREFIX+$#SUFFIX)/3))numeric)'
    
    # Don't complete unavailable commands.
    zstyle ':completion:*:functions' ignored-patterns '(_*|pre(cmd|exec))'
    
    # Array completion element sorting.
    zstyle ':completion:*:*:-subscript-:*' tag-order indexes parameters
    
    # Directories
    export LSCOLORS=DxFxCxdxBxegedabagacad
    export LS_COLORS='di=01;33:ln=01;35:so=01;32:ex=01;31:bd=46;34:cd=43;34:su=41;30:sg=46;30:tw=42;30:ow=43;30'
    
	    # zstyle ':completion:*' list-colors 'di=;33;1' 'ln=;35;1' 'so=;32;1' 'ex=31;1' 'bd=46;34' 'cd=43;34'
    zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
    zstyle ':completion:*:*:cd:*' tag-order local-directories directory-stack path-directories
    zstyle ':completion:*:*:cd:*:directory-stack' menu yes select
    zstyle ':completion:*:-tilde-:*' group-order 'named-directories' 'path-directories' 'users' 'expand'
    zstyle ':completion:*' squeeze-slashes true

    # History
    zstyle ':completion:*:history-words' stop yes
    zstyle ':completion:*:history-words' remove-all-dups yes
    zstyle ':completion:*:history-words' list false
    zstyle ':completion:*:history-words' menu yes
    
    # Environment Variables
    zstyle ':completion::*:(-command-|export):*' fake-parameters ${${${_comps[(I)-value-*]#*,}%%,*}:#-*-}
    
    # Populate hostname completion. But allow ignoring custom entries from static
    # */etc/hosts* which might be uninteresting.
    zstyle -a ':prezto:module:completion:*:hosts' etc-host-ignores '_etc_host_ignores'
    
zstyle -e ':completion:*:hosts' hosts 'reply=(
      ${=${=${=${${(f)"$(cat {/etc/ssh/ssh_,~/.ssh/}known_hosts(|2)(N) 2> /dev/null)"}%%[#| ]*}//\]:[0-9]*/ }//,/ }//\[/ }
      ${=${(f)"$(cat /etc/hosts(|)(N) <<(ypcat hosts 2> /dev/null))"}%%(\#${_etc_host_ignores:+|${(j:|:)~_etc_host_ignores}})*}
      ${=${${${${(@M)${(f)"$(cat ~/.ssh/config 2> /dev/null)"}:#Host *}#Host }:#*\**}:#*\?*}}
    )'
    
    # Don't complete uninteresting users...
    zstyle ':completion:*:*:*:users' ignored-patterns \
      adm amanda apache avahi beaglidx bin cacti canna clamav daemon \
      dbus distcache dovecot fax ftp games gdm gkrellmd gopher \
      hacluster haldaemon halt hsqldb ident junkbust ldap lp mail \
      mailman mailnull mldonkey mysql nagios \
      named netdump news nfsnobody nobody nscd ntp nut nx openvpn \
      operator pcap postfix postgres privoxy pulse pvm quagga radvd \
      rpc rpcuser rpm shutdown squid sshd sync uucp vcsa xfs '_*'
    
    # ... unless we really want to.
    zstyle '*' single-ignored show
    
    # Ignore multiple entries.
    zstyle ':completion:*:(rm|kill|diff):*' ignore-line other
    zstyle ':completion:*:rm:*' file-patterns '*:all-files'

    # auto rehash
    zstyle ':completion:*' rehash true

    #highlight prefix
    zstyle -e ':completion:*:default' list-colors 'reply=("${PREFIX:+=(#bi)($PREFIX:t)*==34=34}:${(s.:.)LS_COLORS}")'

    # Kill
    zstyle ':completion:*:*:*:*:processes' command 'ps -u $LOGNAME -o pid,user,command -w'
    zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;36=0=01'
    zstyle ':completion:*:*:kill:*' menu yes select
    zstyle ':completion:*:*:kill:*' force-list always
    zstyle ':completion:*:*:kill:*' insert-ids single
    
    # Man
    zstyle ':completion:*:manuals' separate-sections true
    zstyle ':completion:*:manuals.(^1*)' insert-sections true
    
    # Media Players
    zstyle ':completion:*:*:mpg123:*' file-patterns '*.(mp3|MP3):mp3\ files *(-/):directories'
    zstyle ':completion:*:*:mpg321:*' file-patterns '*.(mp3|MP3):mp3\ files *(-/):directories'
    zstyle ':completion:*:*:ogg123:*' file-patterns '*.(ogg|OGG|flac):ogg\ files *(-/):directories'
    zstyle ':completion:*:*:mocp:*' file-patterns '*.(wav|WAV|mp3|MP3|ogg|OGG|flac):ogg\ files *(-/):directories'
    
    # Mutt
    if [[ -s "$HOME/.mutt/aliases" ]]; then
      zstyle ':completion:*:*:mutt:*' menu yes select
      zstyle ':completion:*:mutt:*' users ${${${(f)"$(<"$HOME/.mutt/aliases")"}#alias[[:space:]]}%%[[:space:]]*}
    fi
    
    # SSH/SCP/RSYNC
    zstyle ':completion:*:(ssh|scp|rsync):*' tag-order 'hosts:-host:host hosts:-domain:domain hosts:-ipaddr:ip\ address *'
    zstyle ':completion:*:(scp|rsync):*' group-order users files all-files hosts-domain hosts-host hosts-ipaddr
    zstyle ':completion:*:ssh:*' group-order users hosts-domain hosts-host users hosts-ipaddr
    zstyle ':completion:*:(ssh|scp|rsync):*:hosts-host' ignored-patterns '*(.|:)*' loopback ip6-loopback localhost ip6-localhost broadcasthost
    zstyle ':completion:*:(ssh|scp|rsync):*:hosts-domain' ignored-patterns '<->.<->.<->.<->' '^[-[:alnum:]]##(.[-[:alnum:]]##)##' '*@*'
    zstyle ':completion:*:(ssh|scp|rsync):*:hosts-ipaddr' ignored-patterns '^(<->.<->.<->.<->|(|::)([[:xdigit:].]##:(#c,2))##(|%*))' '127.0.0.<->' '255.255.255.255' '::1' 'fe80::*'
}
# }}}
# {{{rtv
export RTV_EDITOR="vim"
export RTV_BROWSER="w3m"
export RTV_URLVIEWER="urlscan"
# }}}
# }}}
# {{{Functions
test_cmd_pre() { # {{{
    command -v "$1" >/dev/null
} # }}}
test_cmd() { # {{{
    test_cmd_pre "$1" && echo 'yes' || echo 'no'
} # }}}
# {{{FuzzyFinder
# fuzzy match dirs and cd
cdf() {
    local dir
    dir=$(find ${1:-.} -path '*/\.*' -prune \
        -o -type d -print 2> /dev/null | "$FuzzyFinder") &&
        cd "$dir"
    }
# include hidden dirs
cdf-all() {
    local dir
    dir=$(find ${1:-.} -type d 2> /dev/null | grep -v ".git/" | "$FuzzyFinder") && cd "$dir"
}
# job to fore
job-fore() {
    JOB_ID=$(jobs | grep "[[[:digit:]]*]" | "$FuzzyFinder" | grep -o "[[[:digit:]]*]" | grep -o "[[:digit:]]*")
    fg %"$JOB_ID"
}

# job to back
job-back() {
    JOB_ID=$(jobs | grep "[[[:digit:]]*]" | "$FuzzyFinder" | grep -o "[[[:digit:]]*]" | grep -o "[[:digit:]]*")
    bg %"$JOB_ID"
}

# job kill
job-kill() {
    JOB_ID=$(jobs | grep "[[[:digit:]]*]" | "$FuzzyFinder" | grep -o "[[[:digit:]]*]" | grep -o "[[:digit:]]*")
    kill %"$JOB_ID"
}

# ps ls
ps-ls() {
    PROC_ID_ORIGIN=$(ps -alf | "$FuzzyFinder")
    if [[ $(echo "$PROC_ID_ORIGIN" | grep "UID[[:blank:]]*PID")x == ""x ]]; then
        PROC_ID=$(echo "$PROC_ID_ORIGIN" | grep -o '^[^[:blank:]]*[[:blank:]]*[^[:blank:]]*[[:blank:]]*[^[:blank:]]*[[:blank:]]*[^[:blank:]]*' | grep -o '[[:digit:]]*$')
        echo "$PROC_ID_ORIGIN"
    fi
}

# ps ls all
ps-ls-all() {
    PROC_ID_ORIGIN=$(ps -elf | "$FuzzyFinder")
    if [[ $(echo "$PROC_ID_ORIGIN" | grep "UID[[:blank:]]*PID")x == ""x ]]; then
        PROC_ID=$(echo "$PROC_ID_ORIGIN" | grep -o '^[^[:blank:]]*[[:blank:]]*[^[:blank:]]*[[:blank:]]*[^[:blank:]]*[[:blank:]]*[^[:blank:]]*' | grep -o '[[:digit:]]*$')
        echo "$PROC_ID_ORIGIN"
    fi
}

# ps info
ps-info() {
    PROC_ID_ORIGIN=$(ps -alf | "$FuzzyFinder")
    if [[ $(echo "$PROC_ID_ORIGIN" | grep "UID[[:blank:]]*PID")x == ""x ]]; then
        PROC_ID=$(echo "$PROC_ID_ORIGIN" | grep -o '^[^[:blank:]]*[[:blank:]]*[^[:blank:]]*[[:blank:]]*[^[:blank:]]*[[:blank:]]*[^[:blank:]]*' | grep -o '[[:digit:]]*$')
        top -p "$PROC_ID"
    fi
}

# ps info all
ps-info-all() {
    PROC_ID_ORIGIN=$(ps -elf | "$FuzzyFinder")
    if [[ $(echo "$PROC_ID_ORIGIN" | grep "UID[[:blank:]]*PID")x == ""x ]]; then
        PROC_ID=$(echo "$PROC_ID_ORIGIN" | grep -o '^[^[:blank:]]*[[:blank:]]*[^[:blank:]]*[[:blank:]]*[^[:blank:]]*[[:blank:]]*[^[:blank:]]*' | grep -o '[[:digit:]]*$')
        top -p "$PROC_ID"
    fi
}

# ps tree
ps-tree() {
    PROC_ID_ORIGIN=$(ps -alf | "$FuzzyFinder")
    if [[ $(echo "$PROC_ID_ORIGIN" | grep "UID[[:blank:]]*PID")x == ""x ]]; then
        PROC_ID=$(echo "$PROC_ID_ORIGIN" | grep -o '^[^[:blank:]]*[[:blank:]]*[^[:blank:]]*[[:blank:]]*[^[:blank:]]*[[:blank:]]*[^[:blank:]]*' | grep -o '[[:digit:]]*$')
        pstree -p "$PROC_ID"
    fi
}

# ps tree all
ps-tree-all() {
    PROC_ID_ORIGIN=$(ps -elf | "$FuzzyFinder")
    if [[ $(echo "$PROC_ID_ORIGIN" | grep "UID[[:blank:]]*PID")x == ""x ]]; then
        PROC_ID=$(echo "$PROC_ID_ORIGIN" | grep -o '^[^[:blank:]]*[[:blank:]]*[^[:blank:]]*[[:blank:]]*[^[:blank:]]*[[:blank:]]*[^[:blank:]]*' | grep -o '[[:digit:]]*$')
        pstree -p "$PROC_ID"
    fi
}

# ps kill
ps-kill() {
    PROC_ID_ORIGIN=$(ps -alf | "$FuzzyFinder")
    if [[ $(echo "$PROC_ID_ORIGIN" | grep "UID[[:blank:]]*PID")x == ""x ]]; then
        PROC_ID=$(echo "$PROC_ID_ORIGIN" | grep -o '^[^[:blank:]]*[[:blank:]]*[^[:blank:]]*[[:blank:]]*[^[:blank:]]*[[:blank:]]*[^[:blank:]]*' | grep -o '[[:digit:]]*$')
        kill -9 "$PROC_ID"
    fi
}

# ps kill
ps-kill-all() {
    PROC_ID_ORIGIN=$(ps -elf | "$FuzzyFinder")
    if [[ $(echo "$PROC_ID_ORIGIN" | grep "UID[[:blank:]]*PID")x == ""x ]]; then
        PROC_ID=$(echo "$PROC_ID_ORIGIN" | grep -o '^[^[:blank:]]*[[:blank:]]*[^[:blank:]]*[[:blank:]]*[^[:blank:]]*[[:blank:]]*[^[:blank:]]*' | grep -o '[[:digit:]]*$')
        kill -9 "$PROC_ID"
    fi
}
# }}}
# {{{zcomp-gen
zcomp-gen () {
    echo "[1] manpage  [2] help"
    read -r var
    if [[ "$var"x == ""x ]]; then
        var=1
    fi
    if [[ "$var"x == "1"x ]]; then
        TARGET=$(find -L /usr/share/man -type f -print -o -type l \
            -print -o  \( -path '*/\.*' -o -fstype 'devfs' -o -fstype 'devtmpfs' -o -fstype 'proc' \) \
            -prune 2> /dev/null |\
            sed 's|\./||g' |\
            sed '1i [cancel]' |\
            fzf)
        if [[ "$TARGET"x == "[cancel]"x ]]; then
            echo ""
        else
            echo "$TARGET" | xargs -i sh ~/.zinit/plugins/nevesnunes---sh-manpage-completions/gencomp-manpage {}
            zpcompinit
        fi
    elif [[ "$var"x == "2"x ]]; then
        TARGET=$(compgen -cb | sed '1i [cancel]' | fzf)
        if [[ "$TARGET"x == "[cancel]"x ]]; then
            echo ""
        else
            gencomp "$TARGET"
            zpcompinit
        fi
    fi
}

# }}}
# {{{Plugins
# https://github.com/zdharma/zinit
# https://github.com/robbyrussell/oh-my-zsh/wiki/Plugins-Overview
# https://github.com/sorin-ionescu/prezto
source ~/.zinit/bin/zinit.zsh
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit
zinit light romkatv/powerlevel10k
zinit light zdharma/fast-syntax-highlighting
zinit light zsh-users/zsh-autosuggestions
zinit ice wait'0' lucid; zinit light zsh-users/zsh-history-substring-search
zinit ice wait'1' lucid; zinit light ytet5uy4/fzf-widgets
zinit ice wait'0' lucid; zinit light urbainvaes/fzf-marks
zinit ice wait'1' lucid; zinit light hlissner/zsh-autopair
zinit ice wait'1' lucid; zinit light peterhurford/git-it-on.zsh
zinit ice wait'1' lucid; zinit snippet OMZ::plugins/vi-mode/vi-mode.plugin.zsh
zinit ice wait'1' lucid; zinit snippet OMZ::plugins/command-not-found/command-not-found.plugin.zsh
zinit ice wait'1' lucid; zinit light denysdovhan/gitio-zsh
zinit ice wait'0' blockf lucid; zinit light sainnhe/zsh-completions
zinit ice wait'0' lucid; zinit light RobSis/zsh-completion-generator
zinit ice wait'0' atload"export FPATH=$HOME/.zinit/plugins/RobSis---zsh-completion-generator/completions:$HOME/.zinit/plugins/nevesnunes---sh-manpage-completions/completions/zsh:$FPATH; zcomp_init" as"program" atclone"mv run.sh gencomp-manpage; sed -i -e '1i pushd ~/.zinit/plugins/nevesnunes---sh-manpage-completions/' -e '\$a popd' gencomp-manpage" pick"run.sh" lucid; zinit light nevesnunes/sh-manpage-completions
zinit ice wait'0' pick".zsh-snippets" lucid; zinit light "$HOME"
source "$HOME/.zsh-theme"
# {{{fast-syntax-highlighting
FAST_HIGHLIGHT[chroma-git]="chroma/-ogit.ch"
# }}}
# {{{fzf
export FZF_DEFAULT_COMMAND='fd --type f'
export FZF_DEFAULT_OPTS="
-m --height=50%
--layout=reverse
--prompt='➤ '
--ansi
--tabstop=4
--color=dark
--color=bg:-1,hl:2,fg+:4,bg+:-1,hl+:2
--color=info:1,prompt:2,pointer:5,marker:1,spinner:3,header:11
--bind=tab:down,btab:up,ctrl-s:toggle,ctrl-p:toggle-preview
"

source ~/.vim/plugged/gruvbox/gruvbox_256palette.sh

#Alias
# Alias
alias cls="clear"
alias down="cd ~/Downloads"
alias ..="cd .."
alias ....="cd ../.."
alias prog="cd ~/Documents/program"
alias look="sudo find . -name"
alias search="sudo grep --color -rnw ./ -e "
alias ports="sudo lsof -PiTCP -sTCP:LISTEN"
alias pause="spotify pause"
alias play="spotify play"
alias next="spotify next"
alias prev="spotify prev"
alias song="spotify status"
alias speedtest="wget -O /dev/null cachefly.cachefly.net/100mb.test"
# alias ls="ls -G"
alias vimsheet="imgcat ~/Documents/div/vimsheet.png"
alias l="ls -l"
alias python=/usr/local/bin/python3

bindkey '^F'  fzf-select-widget
# }}}
# {{{fzf-marks
# Usage: mark fzm C-d
FZF_MARKS_FILE="$HOME/.cache/fzf-marks"
FZF_MARKS_COMMAND="fzf"
FZF_MARKS_COLOR_RHS="249"
# }}}
# {{{zsh-autosuggestions
export ZSH_AUTOSUGGEST_USE_ASYNC="true"
export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=244"
export LS_COLORS
export CLICOLOR=1
bindkey '^[^M' autosuggest-execute


test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

