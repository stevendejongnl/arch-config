#
# ~/.bash_profile
#

if [[ -z $DISPLAY ]] && [[ $(tty) = /dev/tty1 ]]; then
  startx
fi

[[ -f ~/.bashrc ]] && . ~/.bashrc
. "$HOME/.cargo/env"

# Added by LM Studio CLI (lms)
export PATH="$PATH:/home/stevendejong/.lmstudio/bin"
# End of LM Studio CLI section

# Added by JetBrains Context CLI installer
case ":$PATH:" in
    *":/home/stevendejong/.jbcontext/bin:"*) ;;
    *) export PATH="$PATH:/home/stevendejong/.jbcontext/bin" ;;
esac
