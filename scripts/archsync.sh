#!/usr/bin/env bash
# archsync - keep the arch-config repo in sync across machines.
#
# Run `archsync check` at session start (the .zshrc hook does this): it fetches
# origin at most once every ARCHSYNC_TTL_HOURS, then reports whether the local
# main branch is behind / ahead / diverged / dirty. If behind, it offers to pull.
#
#   archsync check    fetch (throttled) + report; prompt to pull/push (default)
#   archsync status   report only, no network, no prompt
#   archsync fetch    force fetch now, ignore throttle
#   archsync pull     fetch + fast-forward pull now
#   archsync push     fetch + push local commits now
#   archsync --selftest   run the built-in tests

set -euo pipefail

REPO="${ARCHSYNC_REPO:-$HOME/.config/arch-config}"
TTL_HOURS="${ARCHSYNC_TTL_HOURS:-4}"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/archsync"
STAMP="$CACHE_DIR/last-fetch"
BRANCH="main"

c_reset=$'\e[0m'; c_dim=$'\e[2m'; c_yellow=$'\e[33m'; c_green=$'\e[32m'; c_red=$'\e[31m'

_git() { git -C "$REPO" "$@"; }

# true if $STAMP is missing or older than TTL_HOURS
_fetch_is_stale() {
  [[ -f "$STAMP" ]] || return 0
  local age_limit=$(( TTL_HOURS * 3600 ))
  local mtime now
  mtime=$(stat -c %Y "$STAMP" 2>/dev/null || echo 0)
  now=$(date +%s)
  (( now - mtime >= age_limit ))
}

_do_fetch() {
  mkdir -p "$CACHE_DIR"
  if _git fetch --quiet origin 2>/dev/null; then
    touch "$STAMP"
    return 0
  fi
  # network down / no auth: don't nag, just skip. Leave stamp so we retry next TTL.
  return 1
}

# echoes one of: uptodate | ahead <n> | behind <n> | diverged <a> <b>
_branch_state() {
  local counts ahead behind
  # left = local ahead, right = local behind
  counts=$(_git rev-list --left-right --count "${BRANCH}...origin/${BRANCH}" 2>/dev/null) || {
    echo "unknown"; return
  }
  ahead=${counts%%$'\t'*}
  behind=${counts##*$'\t'}
  if (( ahead == 0 && behind == 0 )); then echo "uptodate"
  elif (( behind == 0 )); then echo "ahead $ahead"
  elif (( ahead == 0 )); then echo "behind $behind"
  else echo "diverged $ahead $behind"
  fi
}

_is_dirty() { [[ -n "$(_git status --porcelain 2>/dev/null)" ]]; }

_report() {
  local state="$1" dirty_note=""
  _is_dirty && dirty_note=" ${c_yellow}●${c_reset} uncommitted changes"
  case "$state" in
    uptodate)
      # stay quiet unless dirty - no news is good news at session start
      [[ -n "$dirty_note" ]] && printf 'arch-config:%s\n' "$dirty_note"
      ;;
    ahead\ *)
      printf 'arch-config: %s↑ %s to push%s%s\n' "$c_dim" "${state#ahead }" "$c_reset" "$dirty_note"
      ;;
    behind\ *)
      printf 'arch-config: %s↓ %s behind origin%s%s\n' "$c_yellow" "${state#behind }" "$c_reset" "$dirty_note"
      ;;
    diverged\ *)
      local a b; read -r _ a b <<<"$state"
      printf 'arch-config: %s⇅ diverged (%s local, %s remote)%s%s\n' "$c_red" "$a" "$b" "$c_reset" "$dirty_note"
      ;;
    unknown)
      printf 'arch-config: %s? cannot compare to origin%s\n' "$c_dim" "$c_reset"
      ;;
  esac
}

_pull() {
  if _is_dirty; then
    printf '%sWorking tree dirty - commit or stash first, then: archsync pull%s\n' "$c_yellow" "$c_reset"
    return 1
  fi
  if _git pull --ff-only --quiet origin "$BRANCH"; then
    printf '%s✓ pulled%s\n' "$c_green" "$c_reset"
    printf '  dotfiles/system may have changed - run: dcli sync  (and scripts/dotfiles-deploy.sh)\n'
    return 0
  fi
  printf '%s✗ pull failed (diverged?) - resolve manually in %s%s\n' "$c_red" "$REPO" "$c_reset"
  return 1
}

cmd_check() {
  [[ -d "$REPO/.git" ]] || { printf 'archsync: %s is not a git repo\n' "$REPO" >&2; return 0; }
  _fetch_is_stale && _do_fetch || true
  local state; state=$(_branch_state)
  _report "$state"
  # only prompt when there's an action AND we have a terminal
  [[ -t 0 && -t 1 ]] || return 0
  local ans
  case "$state" in
    behind\ *|diverged\ *)
      printf 'Pull now? [y/N] '
      read -r ans
      [[ "$ans" == [yY]* ]] && _pull || true ;;
    ahead\ *)
      _is_dirty && return 0   # commit first; don't nag mid-work
      printf 'Push now? [y/N] '
      read -r ans
      [[ "$ans" == [yY]* ]] && _push || true ;;
  esac
}

cmd_status() {
  [[ -d "$REPO/.git" ]] || { printf 'archsync: %s is not a git repo\n' "$REPO" >&2; return 1; }
  local state; state=$(_branch_state)
  printf 'repo:   %s\n' "$REPO"
  printf 'branch: %s vs origin/%s -> %s\n' "$BRANCH" "$BRANCH" "$state"
  _is_dirty && printf 'tree:   dirty\n' || printf 'tree:   clean\n'
  if [[ -f "$STAMP" ]]; then
    printf 'fetch:  last %s\n' "$(date -d "@$(stat -c %Y "$STAMP")" '+%Y-%m-%d %H:%M')"
  else
    printf 'fetch:  never\n'
  fi
}

_push() {
  local state; state=$(_branch_state)
  case "$state" in
    ahead\ *)
      if _git push --quiet origin "$BRANCH"; then
        printf '%s✓ pushed %s commit(s)%s\n' "$c_green" "${state#ahead }" "$c_reset"
        return 0
      fi
      printf '%s✗ push failed%s\n' "$c_red" "$c_reset"; return 1 ;;
    uptodate)  printf 'nothing to push\n' ;;
    behind\ *) printf '%sbehind origin - pull first: archsync pull%s\n' "$c_yellow" "$c_reset"; return 1 ;;
    diverged\ *) printf '%sdiverged - resolve manually in %s%s\n' "$c_red" "$REPO" "$c_reset"; return 1 ;;
    *) printf '%scannot compare to origin%s\n' "$c_dim" "$c_reset"; return 1 ;;
  esac
}

cmd_fetch() { _do_fetch && printf 'fetched\n' || { printf 'fetch failed\n' >&2; return 1; }; }
cmd_pull()  { _do_fetch || true; _pull; }
cmd_push()  { _do_fetch || true; _push; }

selftest() {
  local tmp; tmp=$(mktemp -d)
  trap 'rm -rf "${tmp:-}"' EXIT
  export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null
  local pass=0 fail=0
  _ok()   { printf '  ok   %s\n' "$1"; pass=$((pass+1)); }
  _bad()  { printf '  FAIL %s\n' "$1"; fail=$((fail+1)); }

  # bare origin + two clones
  git init -q --bare "$tmp/origin.git"
  git clone -q "$tmp/origin.git" "$tmp/a"
  git -C "$tmp/a" -c user.email=t@t -c user.name=t commit -q --allow-empty -m init
  git -C "$tmp/a" branch -M main
  git -C "$tmp/a" push -q -u origin main
  git clone -q "$tmp/origin.git" "$tmp/b"
  git -C "$tmp/b" checkout -q -B main origin/main

  REPO="$tmp/b"; CACHE_DIR="$tmp/cache"; STAMP="$CACHE_DIR/last-fetch"; mkdir -p "$CACHE_DIR"

  # 1. in sync
  _do_fetch >/dev/null
  [[ "$(_branch_state)" == uptodate ]] && _ok "detects uptodate" || _bad "uptodate: got '$(_branch_state)'"

  # 2. origin moves ahead -> local behind
  git -C "$tmp/a" -c user.email=t@t -c user.name=t commit -q --allow-empty -m remote1
  git -C "$tmp/a" push -q origin main
  _do_fetch >/dev/null
  [[ "$(_branch_state)" == "behind 1" ]] && _ok "detects behind" || _bad "behind: got '$(_branch_state)'"

  # 3. pull fast-forwards
  _pull >/dev/null
  [[ "$(_branch_state)" == uptodate ]] && _ok "pull ff resolves behind" || _bad "post-pull: got '$(_branch_state)'"

  # 4. local commit -> ahead
  git -C "$tmp/b" -c user.email=t@t -c user.name=t commit -q --allow-empty -m local1
  [[ "$(_branch_state)" == "ahead 1" ]] && _ok "detects ahead" || _bad "ahead: got '$(_branch_state)'"

  # 4b. push resolves ahead
  _push >/dev/null
  [[ "$(_branch_state)" == uptodate ]] && _ok "push resolves ahead" || _bad "post-push: got '$(_branch_state)'"

  # 5. both sides move -> diverged
  git -C "$tmp/a" pull -q --ff-only origin main
  git -C "$tmp/a" -c user.email=t@t -c user.name=t commit -q --allow-empty -m remote2
  git -C "$tmp/a" push -q origin main
  git -C "$tmp/b" -c user.email=t@t -c user.name=t commit -q --allow-empty -m local2
  _do_fetch >/dev/null
  case "$(_branch_state)" in diverged\ 1\ 1) _ok "detects diverged" ;; *) _bad "diverged: got '$(_branch_state)'" ;; esac
  # push refuses when diverged
  _push >/dev/null 2>&1 && _bad "push should refuse when diverged" || _ok "push refuses when diverged"

  # 6. dirty tree detected
  echo x > "$tmp/b/dirtyfile"
  _is_dirty && _ok "detects dirty tree" || _bad "dirty tree not detected"

  # 7. fetch throttle: fresh stamp -> stale check false
  touch "$STAMP"
  _fetch_is_stale && _bad "fresh stamp reported stale" || _ok "throttle: fresh stamp skips fetch"
  # old stamp -> stale
  touch -d '10 hours ago' "$STAMP"
  _fetch_is_stale && _ok "throttle: old stamp triggers fetch" || _bad "old stamp not stale"

  printf '\n%d passed, %d failed\n' "$pass" "$fail"
  [[ $fail -eq 0 ]]
}

main() {
  case "${1:-check}" in
    check)       cmd_check ;;
    status)      cmd_status ;;
    fetch)       cmd_fetch ;;
    pull)        cmd_pull ;;
    push)        cmd_push ;;
    --selftest)  selftest ;;
    -h|--help)   sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//' ;;
    *) printf 'archsync: unknown command %s (try --help)\n' "$1" >&2; return 2 ;;
  esac
}

main "$@"
