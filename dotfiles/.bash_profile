#
# ~/.bash_profile
#

# Login shell is zsh (see .zprofile); this is the fallback if bash is ever
# the login shell on tty1. Keep in sync with .zprofile.
if [[ -z $DISPLAY ]] && [[ $(tty) = /dev/tty1 ]]; then
  pgrep -x dwm > /dev/null || exec startx "$HOME/.config/X11/xinitrc"
fi

[[ -f ~/.bashrc ]] && . ~/.bashrc
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# Added by LM Studio CLI (lms)
export PATH="$PATH:/home/stevendejong/.lmstudio/bin"
# End of LM Studio CLI section

# Added by JetBrains Context CLI installer
case ":$PATH:" in
    *":/home/stevendejong/.jbcontext/bin:"*) ;;
    *) export PATH="$PATH:/home/stevendejong/.jbcontext/bin" ;;
esac
