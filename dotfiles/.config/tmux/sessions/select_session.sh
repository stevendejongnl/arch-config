#! /bin/bash

get_session() {
    ls $HOME/.config/tmux/sessions/*.conf | xargs -n1 basename | sed 's/\.conf$//'
}

select_session() {
    session_name=$(tmux command-prompt -p "Choose session: " "" "run-shell 'ls ~/.config/tmux/sessions/*.conf | xargs -n1 basename | sed 's/\.conf$//' | grep -v '^$' | tr '\n' '|' | sed 's/|$//' | xargs -I {} echo {}' | cat")
    if [ -n "$session_name" ]; then
        tmux new-session -d -s "$session_name" -c ~/.config/tmux/sessions
        tmux source-file ~/.config/tmux/sessions/${session_name}.conf
    fi
}

select_session
