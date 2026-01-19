#!/bin/bash

# profile
OVPN_CONFIG="$HOME/.openvpn3/autoload/cloudsuite.ovpn"

DB_KEY="vpn.cloudsuite.com"

# Check if the configuration file exists
if [ ! -f "$OVPN_CONFIG" ]; then
  echo "Configuration file not found: $OVPN_CONFIG"
  exit 1
fi

# Retrieve email (username) and password from 1Password CLI
USERNAME=$(op item get "$DB_KEY" --fields label=username)
PASSWORD=$(op item get "$DB_KEY" --fields label=password --reveal)

if [ -z "$USERNAME" ] || [ -z "$PASSWORD" ]; then
  echo "Failed to retrieve username or password from 1Password."
  exit 1
fi

# Create a temporary credentials file with username and password only
CREDENTIALS_FILE=$(mktemp)
echo -e "$USERNAME\n$PASSWORD" > "$CREDENTIALS_FILE"
chmod 600 "$CREDENTIALS_FILE"

# Start OpenVPN and let the user manually input the OTP when prompted
echo "Starting OpenVPN. You will need to manually enter the OTP when prompted."
sudo openvpn --config "$OVPN_CONFIG" --auth-user-pass "$CREDENTIALS_FILE"

# Clean up the temporary credentials file
rm -f "$CREDENTIALS_FILE"
