#!/bin/bash

# profile
OVPN_CONFIG="$HOME/.openvpn3/autoload/cloudsuite.ovpn"

# 1Password database key
DB_KEY="vpn.cloudsuite.com"

# commands
COMMAND_COUNT=0
COMMAND_START=false
COMMAND_STOP=false
COMMAND_LIST=false
COMMAND_IMPORT=false

# arguments
ARGUMENTS=()

verify_command() {
  if [ $COMMAND_COUNT -eq 0 ]; then
    COMMAND_START=true
  elif [ $COMMAND_COUNT -ne 1 ]; then
    echo "Specify exacly 1 command."
    exit 1
  fi
}

execute_command() {
  if [ $COMMAND_START = true ]; then
    command_start
  elif [ $COMMAND_STOP = true ]; then
    command_stop
  elif [ $COMMAND_LIST = true ]; then
    command_list
  elif [ $COMMAND_IMPORT = true ]; then
    command_import
  fi
}

command_start() {
  local USERNAME=`op item get ${DB_KEY} --fields label=username`
  local PASSWORD=`op item get ${DB_KEY} --fields label=password --reveal`
  local ONE_TIME=`op item get ${DB_KEY} --otp`

  printf "$USERNAME\n$PASSWORD\n$ONE_TIME\n" | openvpn3 session-start --config "${OVPN_CONFIG}"
}

command_stop() {
  openvpn3 sessions-list | grep Path | awk -v OFS='\t' '{print $2}' | while read -r path; do
    openvpn3 session-manage --path "$path" --disconnect
  done
}

command_list() {
  openvpn3 sessions-list
}

command_import() {
  if [ -z "${ARGUMENTS[0]}" ]; then
    echo "Missing a config file (*.ovpn) argument."
    exit 1
  fi

  openvpn3 config-import --config "${ARGUMENTS[0]}"
}

main() {
  verify_command
  execute_command
}

print_help() {
  echo \
  "
  Simple way to connect and disconnect to openvpn3 server.
  Will interface with 1Password via its CLI.
  See: https://developer.1password.com/docs/cli/get-started

  Commands:
    start          Starts a new session, prompts for system authentication.
    stop           Takes the first active session and disconnect it.
    list           Show active sessions.
    import <path>  Add new configuration file.

  Options:
    -h, --help     This help text.
  "
}

while [ $# -gt 0 ]; do
  key="$1"

  case $key in
    # help
    -h|--help)
      print_help
      exit
      ;;

    # commands
    start)
      ((COMMAND_COUNT+=1))
      COMMAND_START=true
      shift
      ;;
    stop)
      ((COMMAND_COUNT+=1))
      COMMAND_STOP=true
      shift
      ;;
    list)
      ((COMMAND_COUNT+=1))
      COMMAND_LIST=true
      shift
      ;;
    import)
      ((COMMAND_COUNT+=1))
      COMMAND_IMPORT=true
      shift
      ;;
      
    # arguments
    *)
      ARGUMENTS+=("$1")
      shift
      ;;
  esac
done

main
