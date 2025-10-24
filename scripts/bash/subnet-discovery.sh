#!/usr/bin/env bash

# Usage: ./subnet_scan.sh <subnet>
# Example: ./subnet_scan.sh 192.168.1.0/24

if [ -z "$1" ]; then
  echo "Usage: $0 <subnet>"
  exit 1
fi

subnet="$1"

# Check dependencies
for cmd in fping nmap dig; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Error: '$cmd' is required but not installed." >&2
    exit 1
  fi
done

# Temporary files
TMP_LIVE="/tmp/live_hosts_$$.txt"
> "$TMP_LIVE"

echo "[+] Performing fast ICMP sweep with fping..."
fping -a -q -g "$subnet" 2>/dev/null > "$TMP_LIVE"

# If no live hosts found by fping, fallback to nmap ARP discovery
if [ ! -s "$TMP_LIVE" ]; then
  echo "[!] No ICMP responses found. Trying ARP-based discovery with nmap..."
  nmap -sn -PR -T5 -n "$subnet" 2>/dev/null | awk '/Nmap scan report/{print $NF}' > "$TMP_LIVE"
fi

echo "[+] Resolving DNS and verifying final reachability..."
while read -r ip; do
  [ -z "$ip" ] && continue
  dns_name=$(dig +short -x "$ip" 2>/dev/null)
  if [ -n "$dns_name" ]; then
    echo "- $ip    # $dns_name"
  else
    echo "- $ip"
  fi
done < "$TMP_LIVE"

rm -f "$TMP_LIVE"
