source $HOME/.aliases

# SSH auth goes through the Bitwarden agent (set in ~/.zshenv); no stray agent.

if [[ "$(tty)" = "/dev/tty1" ]]; then
  pgrep dwm || startx "$HOME/.config/X11/xinitrc"
fi

