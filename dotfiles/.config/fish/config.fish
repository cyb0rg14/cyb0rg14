#  ███████╗██╗███████╗██╗  ██╗
#  ██╔════╝██║██╔════╝██║  ██║
#  █████╗  ██║███████╗███████║
#  ██╔══╝  ██║╚════██║██╔══██║
#  ██║     ██║███████║██║  ██║
#  ╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝

# My fish config. Not much to see here; just some pretty standard stuff.

### ADDING TO THE PATH
# First line removes the path; second line sets it.  Without the first line,
# your path gets massive and fish becomes very slow.
set -e fish_user_paths
set -U fish_user_paths $HOME/.local/bin/* $HOME/.local/bin/*/* $fish_user_paths

### EXPORT ###
set fish_greeting                                 # Supresses fish's intro message
set TERM "xterm-256color"                         # Sets the terminal type
# set EDITOR "emacsclient -t -a ''"                 # $EDITOR use Emacs in terminal
set -x EDITOR "nvim"
set -x VISUAL "nvim"
# set VISUAL "emacsclient -c -a emacs"              # $VISUAL use Emacs in GUI mode
set TERMINAL "kitty"
set BROWSER "thorium-browser"
set -x PF_INFO "ascii title os wm kernel uptime pkgs memory"
# set -x PF_ASCII "Catppuccin"

### SET MANPAGER
### Uncomment only one of these!

### "bat" as manpager
# set -x MANPAGER "sh -c 'col -bx | bat -l man -p'"

# set -x MANPAGER "nvim +Man!"
function man
    command man $argv[1..-1] | col -bx | bat -l man -p
end

### SET EITHER DEFAULT EMACS MODE OR VI MODE ###
function fish_user_key_bindings
  # fish_default_key_bindings
  fish_vi_key_bindings
end

### END OF VI MODE ###

### AUTOCOMPLETE AND HIGHLIGHT COLORS ###
set fish_color_normal brcyan
set fish_color_autosuggestion '#7d7d7d'
set fish_color_command brcyan
set fish_color_error '#ff6c6b'
set fish_color_param brcyan

### SPARK ###
set -g spark_version 1.0.0

complete -xc spark -n __fish_use_subcommand -a --help -d "Show usage help"
complete -xc spark -n __fish_use_subcommand -a --version -d "$spark_version"
complete -xc spark -n __fish_use_subcommand -a --min -d "Minimum range value"
complete -xc spark -n __fish_use_subcommand -a --max -d "Maximum range value"

function spark -d "sparkline generator"
    if isatty
        switch "$argv"
            case {,-}-v{ersion,}
                echo "spark version $spark_version"
            case {,-}-h{elp,}
                echo "usage: spark [--min=<n> --max=<n>] <numbers...>  Draw sparklines"
                echo "examples:"
                echo "       spark 1 2 3 4"
                echo "       seq 100 | sort -R | spark"
                echo "       awk \\\$0=length spark.fish | spark"
            case \*
                echo $argv | spark $argv
        end
        return
    end

    command awk -v FS="[[:space:],]*" -v argv="$argv" '
        BEGIN {
            min = match(argv, /--min=[0-9]+/) ? substr(argv, RSTART + 6, RLENGTH - 6) + 0 : ""
            max = match(argv, /--max=[0-9]+/) ? substr(argv, RSTART + 6, RLENGTH - 6) + 0 : ""
        }
        {
            for (i = j = 1; i <= NF; i++) {
                if ($i ~ /^--/) continue
                if ($i !~ /^-?[0-9]/) data[count + j++] = ""
                else {
                    v = data[count + j++] = int($i)
                    if (max == "" && min == "") max = min = v
                    if (max < v) max = v
                    if (min > v ) min = v
                }
            }
            count += j - 1
        }
        END {
            n = split(min == max && max ? "▅ ▅" : "▁ ▂ ▃ ▄ ▅ ▆ ▇ █", blocks, " ")
            scale = (scale = int(256 * (max - min) / (n - 1))) ? scale : 1
            for (i = 1; i <= count; i++)
                out = out (data[i] == "" ? " " : blocks[idx = int(256 * (data[i] - min) / scale) + 1])
            print out
        }
    '
end
### END OF SPARK ###


### FUNCTIONS ###
# Spark functions
function letters
    cat $argv | awk -vFS='' '{for(i=1;i<=NF;i++){ if($i~/[a-zA-Z]/) { w[tolower($i)]++} } }END{for(i in w) print i,w[i]}' | sort | cut -c 3- | spark | lolcat
    printf  '%s\n' 'abcdefghijklmnopqrstuvwxyz'  ' ' | lolcat
end

function commits
    git log --author="$argv" --format=format:%ad --date=short | uniq -c | awk '{print $1}' | spark | lolcat
end

# Functions needed for !! and !$
function __history_previous_command
  switch (commandline -t)
  case "!"
    commandline -t $history[1]; commandline -f repaint
  case "*"
    commandline -i !
  end
end

function __history_previous_command_arguments
  switch (commandline -t)
  case "!"
    commandline -t ""
    commandline -f history-token-search-backward
  case "*"
    commandline -i '$'
  end
end
# The bindings for !! and !$
if [ "$fish_key_bindings" = "fish_vi_key_bindings" ];
  bind -Minsert ! __history_previous_command
  bind -Minsert '$' __history_previous_command_arguments
else
  bind ! __history_previous_command
  bind '$' __history_previous_command_arguments
end

# Function for creating a backup file
# ex: backup file.txt
# result: copies file as file.txt.bak
function backup --argument filename
    cp $filename $filename.bak
end

# Function for copying files and directories, even recursively.
# ex: copy DIRNAME LOCATIONS
# result: copies the directory and all of its contents.
function copy
    set count (count $argv | tr -d \n)
    if test "$count" = 2; and test -d "$argv[1]"
	set from (echo $argv[1] | trim-right /)
	set to (echo $argv[2])
        command cp -r $from $to
    else
        command cp $argv
    end
end

# Function for printing a column (splits input on whitespace)
# ex: echo 1 2 3 | coln 3
# output: 3
function coln
    while read -l input
        echo $input | awk '{print $'$argv[1]'}'
    end
end

# Function for printing a row
# ex: seq 3 | rown 3
# output: 3
function rown --argument index
    sed -n "$index p"
end

# Function for ignoring the first 'n' lines
# ex: seq 10 | skip 5
# results: prints everything but the first 5 lines
function skip --argument n
    tail +(math 1 + $n)
end

# Function for taking the first 'n' lines
# ex: seq 10 | take 5
# results: prints only the first 5 lines
function take --argument number
    head -$number
end

# Function for org-agenda
function org-search -d "send a search string to org-mode"
    set -l output (/usr/bin/emacsclient -a "" -e "(message \"%s\" (mapconcat #'substring-no-properties \
        (mapcar #'org-link-display-format \
        (org-ql-query \
        :select #'org-get-heading \
        :from  (org-agenda-files) \
        :where (org-ql--query-string-to-sexp \"$argv\"))) \
        \"
    \"))")
    printf $output
end

function lfcd
    set tmp (mktemp)
    lf -last-dir-path="$tmp" $argv
    if test -f "$tmp"
        set dir (cat "$tmp")
        rm -f "$tmp"
        if test -d "$dir" -a "$dir" != (pwd)
            cd "$dir"
        end
    end
end

function sfi
    find ~/.config/* ~/.local/bin/* -type f | grep -we 'alacritty\|autostart\|cava\|dunst\|fish\|kitty\|nvim\|ranger\|rofi\|picom\|starship.toml\|xmonad\|zathura\|bin\|hyprland' | fzf | xargs -r /usr/bin/nvim
end

function sff
    command ls -a -p | grep -v / | fzf | xargs -r -I % $EDITOR %
end

# function sfd
#     cd "$(echo */ | sed 's/ /\n/g' | fzf)" && ls
# end

function sfd
    set selected_dir (find . -maxdepth 1 -type d | sed 's/.\///' | fzf --prompt='Select a directory: ')

    if test -n "$selected_dir"
        if test -d "$selected_dir"
            cd "$selected_dir"
        end
    end
end


bind -M insert -m default jk 'commandline -f repaint'
bind -M insert \co 'lfcd; commandline -f repaint'
bind -M default \co 'lfcd; commandline -f repaint'
bind -M insert \cj 'sfi; commandline -f repaint'
bind -M default \cj 'sfi; commandline -f repaint'
bind -M insert \cf 'sff; commandline -f repaint'
bind -M default \cf 'sff; commandline -f repaint'
bind -M insert \cd 'sfd; commandline -f repaint'
bind -M default \cd 'sfd; commandline -f repaint'

### END OF FUNCTIONS ###


### ALIASES ###
# \x1b[2J   <- clears tty
# \x1b[1;1H <- goes to (1, 1) (start)
# alias clear='echo -en "\x1b[2J\x1b[1;1H" ; echo; echo; seq 1 (tput cols) | sort -R | spark | lolcat; echo; echo'

# root privileges
alias doas="doas --"

# changing cd to zoxide
alias cd='z'

# navigation
alias ..='z ..'
alias ...='z ../..'
alias .3='z ../../..'
alias .4='z ../../../..'
alias .5='z ../../../../..'

# alias .1='cd ..'
# alias .2='cd ../..'
# alias .3='cd ../../..'
# alias .4='cd ../../../..'
# alias .5='cd ../../../../..'

# vim and emacs
alias v='nvim'
alias em='/usr/bin/emacs -nw'
alias emacs="emacsclient -c -a 'emacs'"
alias doomsync="~/.config/emacs/bin/doom sync"
alias doomdoctor="~/.config/emacs/bin/doom doctor"
alias doomupgrade="~/.config/emacs/bin/doom upgrade"
alias doompurge="~/.config/emacs/bin/doom purge"

# Changing "ls" to "exa"
alias ls='exa --icons --color=always --group-directories-first' # my preferred listing
alias la='exa -a --icons --color=always --group-directories-first'  # all files and dirs
alias ll='exa -al --icons --color=always --group-directories-first'  # long format
alias lt='exa -aT --color=always --group-directories-first' # tree listing
alias l.='exa -a | grep -E "^\."'

# Changing "cat" to "bat"
alias cat="bat"

# Changing "automation-music" to "playmusic"
alias playmusic="automation-music"


# pacman and yay
alias pacsyu='sudo pacman -Syu'                  # update only standard pkgs
alias pacsyyu='sudo pacman -Syyu'                # Refresh pkglist & update standard pkgs
alias yaysua='yay -Sua --noconfirm'              # update only AUR pkgs (yay)
alias yaysyu='yay -Syu --noconfirm'              # update standard pkgs and AUR pkgs (yay)
alias parsua='paru -Sua --noconfirm'             # update only AUR pkgs (paru)
alias parsyu='paru -Syu --noconfirm'             # update standard pkgs and AUR pkgs (paru)
alias unlock='sudo rm /var/lib/pacman/db.lck'    # remove pacman lock
alias cleanup='sudo pacman -Rns (pacman -Qtdq)' # remove orphaned packages
alias upd='sudo pacman -Syyu'                     # To update the system
# alias grubup="update-grub"                      # To update the grub files
alias hw='hwinfo --short'                          # Hardware Info
alias big="expac -H M '%m\t%n' | sort -h | nl"     # Sort installed packages according to size in MB
alias gitpkg='pacman -Q | grep -i "\-git" | wc -l' # List amount of -git packages
alias tarnow='tar -acf '
alias untar='tar -xvf '
alias wget='wget -c '
alias rip="expac --timefmt='%Y-%m-%d %T' '%l\t%n %v' | sort | tail -200 | nl"  # Recent installed pkgs
alias dir='dir --color=auto'    # colorize dir
alias vdir='vdir --color=auto'  # colorize vdir

# get fastest mirrors
alias mirror="sudo reflector -f 30 -l 30 --number 10 --verbose --save /etc/pacman.d/mirrorlist"
alias mirrord="sudo reflector --latest 50 --number 20 --sort delay --save /etc/pacman.d/mirrorlist"
alias mirrors="sudo reflector --latest 50 --number 20 --sort score --save /etc/pacman.d/mirrorlist"
alias mirrora="sudo reflector --latest 50 --number 20 --sort age --save /etc/pacman.d/mirrorlist"

# Colorize grep output (good for log files)
alias grep='grep --color=auto'
alias egrep='grep -E --color=auto'
alias fgrep='fgrep --color=auto'

# confirm before overwriting something
alias cp="cp -i"
alias mv='mv -i'
alias rm="trash-put"
alias tr="trash-restore"
alias tl="trash-list"
alias tempty="trash-empty"
# alias rm='rm -i'

# adding flags
alias df='df -h'                          # human-readable sizes
alias free='free -m'                      # show sizes in MB
alias lynx='lynx -cfg=~/.lynx/lynx.cfg -lss=~/.lynx/lynx.lss -vikeys'
# alias vifm='./.config/vifm/scripts/vifmrun'
# alias ncmpcpp='ncmpcpp ncmpcpp_directory=$HOME/.config/ncmpcpp/'
# alias mocp='mocp -M "$XDG_CONFIG_HOME"/moc -O MOCDir="$XDG_CONFIG_HOME"/moc'

# ps
alias psa="ps auxf"
alias psgrep="ps aux | grep -v grep | grep -i -e VSZ -e"
alias psmem='ps auxf | sort -nr -k 4'
alias pscpu='ps auxf | sort -nr -k 3'

# Merge Xresources
alias merge='xrdb -merge ~/.Xresources'

# git
alias addup='git add -u'
alias addall='git add .'
alias branch='git branch'
alias checkout='git checkout'
alias clone='git clone'
alias commit='git commit -m'
alias fetch='git fetch'
alias pull='git pull origin'
alias push='git push origin'
alias tag='git tag'
alias newtag='git tag -a'

# get error messages from journalctl
alias jctl="journalctl -p 3 -xb"

# gpg encryption
# verify signature for isos
alias gpg-check="gpg2 --keyserver-options auto-key-retrieve --verify"
# receive the key of a developer
alias gpg-retrieve="gpg2 --keyserver-options auto-key-retrieve --receive-keys"

# Play audio files in current dir by type
alias playwav='deadbeef *.wav'
alias playogg='deadbeef *.ogg'
alias playmp3='deadbeef *.mp3'

# Play video files in current dir by type
alias playavi='vlc *.avi'
alias playmov='vlc *.mov'
alias playmp4='vlc *.mp4'

# youtube-dl
alias yta-aac="youtube-dl --extract-audio --audio-format aac "
alias yta-best="youtube-dl --extract-audio --audio-format best "
alias yta-flac="youtube-dl --extract-audio --audio-format flac "
alias yta-m4a="youtube-dl --extract-audio --audio-format m4a "
alias yta-mp3="youtube-dl --extract-audio --audio-format mp3 "
alias yta-opus="youtube-dl --extract-audio --audio-format opus "
alias yta-vorbis="youtube-dl --extract-audio --audio-format vorbis "
alias yta-wav="youtube-dl --extract-audio --audio-format wav "
alias ytv-best="youtube-dl -f bestvideo+bestaudio "

# switch between shells
# I do not recommend switching default SHELL from bash.
alias tobash="sudo chsh $USER -s /bin/bash && echo 'Now log out.'"
alias tozsh="sudo chsh $USER -s /bin/zsh && echo 'Now log out.'"
alias tofish="sudo chsh $USER -s /bin/fish && echo 'Now log out.'"

# bare git repo alias for dotfiles
alias config="/usr/bin/git --git-dir=$HOME/Dotfiles --work-tree=$HOME"

# termbin
alias tb="nc termbin.com 9999"

# the terminal rickroll
alias rr='curl -s -L https://raw.githubusercontent.com/keroserene/rickrollrc/master/roll.sh | bash'

# Unlock LBRY tips
alias tips="lbrynet txo spend --type=support --is_not_my_input --blocking"

# Mocp must be launched with bash instead of Fish!
# alias mocp="bash -c mocp"

### DTOS ###
# Copy/paste all content of /etc/dtos over to home folder. A backup of config is created. (Be careful running this!)
alias dtoscopy='[ -d ~/.config ] || mkdir ~/.config && cp -Rf ~/.config ~/.config-backup-(date +%Y.%m.%d-%H.%M.%S) && cp -rf /etc/dtos/* ~'
# Backup contents of /etc/dtos to a backup folder in $HOME.
alias dtosbackup='cp -Rf /etc/dtos ~/dtos-backup-(date +%Y.%m.%d-%H.%M.%S)'

# Distrobox
alias dbox='/usr/bin/distrobox-enter -T -n cyborgden-- '
alias kali='distrobox enter cyborgden'

# Mysql
alias mysql='mariadb'

# bun (Node package manager)
# alias npm='bun'
# alias npmx='bun x'
# alias bunx='bun x'

# mkdir -p alias
alias mkdir='mkdir -p'

#### Alias to screenshot
# alias sct="dm-maim"

### RANDOM COLOR SCRIPT ###
# Get this script from my GitLab: gitlab.com/dwt1/shell-color-scripts
# Or install it from the Arch User Repository: shell-color-scripts
# colorscript random

# fm6000 -m 8 -g 12 -c green
# fm6000 --random -m 8 -g 12 -c green


function play1 
    mpv --ytdl-format=bestaudio ytdl://ytsearch:"https://youtu.be/L73AMFb8J0E"
    mpv --ytdl-format=bestaudio ytdl://ytsearch:"tu hi yaar mera indian slowed and reverb song"
end

function playhope
    mpv --ytdl-format=bestaudio ytdl://ytsearch:"hope neffex song"
end


# pokemon -r --no-name
nerdfetch

### SETTING THE STARSHIP PROMPT ###
zoxide init fish | source
starship init fish | source

# fish prompt style
# function fish_prompt
#     set -l current_dir (basename (pwd))
#     echo -n -s "$current_dir "
# end

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
if test -f /home/datamaven14/miniconda3/bin/conda
    eval /home/datamaven14/miniconda3/bin/conda "shell.fish" "hook" $argv | source
else
    if test -f "/home/datamaven14/miniconda3/etc/fish/conf.d/conda.fish"
        . "/home/datamaven14/miniconda3/etc/fish/conf.d/conda.fish"
    else
        set -x PATH "/home/datamaven14/miniconda3/bin" $PATH
    end
end
# <<< conda initialize <<<

