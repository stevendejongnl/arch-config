#!/local/bin/env bash

# findpi — discover Raspberry Pi devices on the local network
# Usage: findpi            # runs all checks and prints found hosts
#        findpi quick      # run only a fast ping sweep + SSH check
# Notes: requires sudo for arp-scan; avahi-browse requires avahi-daemon running.
findpi() {
  # Determine local IPv4 CIDR (first global address)
  local cidr
  cidr=$(ip -4 -o addr show scope global | awk '{print $4; exit}')
  if [ -z "$cidr" ]; then
    echo "Could not determine local network CIDR. Are you connected?"
    return 2
  fi

  echo "Network CIDR: $cidr"
  echo

  # 1) mDNS / Avahi - quickest and most reliable if avahi-daemon is running.
  if command -v avahi-browse >/dev/null 2>&1; then
    echo "== mDNS / Avahi (hostnames) =="
    # -r resolve, -t terminate after results, -a all services
    avahi-browse -art 2>/dev/null | awk -F ';' '
      /;IPv4;/ { ip=$8 }
      /;hostname;/ { host=$7 }
      /;local/ && host && ip { print host " -> " ip; host=""; ip="" }
    '
    echo
  else
    echo "avahi-browse not installed. (Install package: avahi)"
    echo
  fi

  # 2) arp-scan — reliable hardware vendor lookup (needs sudo)
  if command -v arp-scan >/dev/null 2>&1; then
    echo "== ARP scan (may require sudo) =="
    if [ "$(id -u)" -ne 0 ]; then
      echo "Running sudo arp-scan --localnet (you'll be prompted for password)"
      sudo arp-scan --localnet 2>/dev/null | awk '/Raspberry Pi/ || /Raspberry/ || /raspberry/ {print}'
    else
      arp-scan --localnet 2>/dev/null | awk '/Raspberry Pi/ || /Raspberry/ || /raspberry/ {print}'
    fi
    echo
  else
    echo "arp-scan not installed. (Install package: arp-scan)"
    echo
  fi

  # 3) Fast ping sweep -> check for open SSH port (22) and optionally banner
  # Use fping if available, otherwise nmap ping-scan
  echo "== Fast ping sweep and SSH check =="
  if command -v fping >/dev/null 2>&1; then
    # get active IPs quickly
    fping -a -g "$cidr" 2>/dev/null | while read -r ip; do
      # quick check if port 22 is open
      timeout 1 bash -c "echo >/dev/tcp/$ip/22" 2>/dev/null && echo "$ip : port 22 open"
    done
  else
    # fallback: nmap ping-scan + check port 22
    if command -v nmap >/dev/null 2>&1; then
      nmap -sn "$cidr" -oG - 2>/dev/null | awk '/Up$/{print $2}' | while read -r ip; do
        # test port 22
        timeout 1 bash -c "echo >/dev/tcp/$ip/22" 2>/dev/null && echo "$ip : port 22 open"
      done
    else
      echo "neither fping nor nmap installed. (Install: fping or nmap)"
    fi
  fi
  echo

  # 4) SSH banner / reverse DNS check for 'raspberrypi' hostnames (optional)
  echo "== Reverse DNS / SSH banner checks for 'raspberrypi' =="
  # build a list of candidate IPs from ARP table and nmap results
  local cand_ips
  cand_ips=$(ip neigh show | awk '/REACHABLE|STALE|DELAY|PERMANENT|PROBE/ {print $1}')
  for ip in $cand_ips; do
    # reverse DNS
    host=$(getent hosts "$ip" | awk '{print $2}')
    if [[ "$host" == *raspberrypi* ]]; then
      echo "$ip -> $host"
      continue
    fi
    # try brief SSH banner grab (non-blocking, short timeout)
    if timeout 1 bash -c "echo >/dev/tcp/$ip/22" 2>/dev/null; then
      banner=$(timeout 2 bash -c "exec 3<>/dev/tcp/$ip/22; head -n1 <&3 2>/dev/null" )
      if echo "$banner" | grep -iq "Raspbian\|Raspberry\|raspberry"; then
        echo "$ip -> SSH banner: $banner"
      fi
    fi
  done

  echo
  echo "Done. If you still don't see expected devices, ensure:"
  echo " - avahi-daemon is running on the Pis (mDNS/hostname discovery)"
  echo " - Pis are powered and connected to the same VLAN/subnet"
  echo " - No network isolation (guest Wi-Fi) is active"
}

