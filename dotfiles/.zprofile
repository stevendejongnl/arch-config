source $HOME/.auth_tokens

eval $(ssh-agent)

if [[ "$(tty)" = "/dev/tty1" ]]; then
  pgrep dwm || startx "$HOME/.config/X11/xinitrc"
fi


# Added by Toolbox App
export PATH="$PATH:/home/stevendejong/.local/share/JetBrains/Toolbox/scripts"

