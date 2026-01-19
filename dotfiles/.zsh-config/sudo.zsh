# Sudo toggle function - add/remove sudo from current command
# Press ESC twice to toggle sudo on/off
sudo-command-line() {
    [[ -z $BUFFER ]] && return
    if [[ $BUFFER == sudo\ * ]]; then
        CURSOR=$(( CURSOR - 5 ))
        BUFFER="${BUFFER#sudo }"
    else
        BUFFER="sudo $BUFFER"
        CURSOR=$(( CURSOR + 5 ))
    fi
}
zle -N sudo-command-line
bindkey "\e\e" sudo-command-line  # Bind ESC ESC
