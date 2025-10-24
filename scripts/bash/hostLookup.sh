#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage: $0 <ip-list-file>"
  exit 1
fi

input_file="$1"

while IFS= read -r line || [ -n "$line" ]; do
  ip=$(echo "$line" | tr -d ' -')  # Remove leading dash or spaces
  if [[ -z "$ip" ]]; then
    continue
  fi

  # Run host and extract all PTR records (the last word in the line)
  dns_records=$(host "$ip" 2>/dev/null | awk '/domain name pointer/ {print $NF}')

  # Concatenate multiple DNS names, add period if missing
  dns_names=""
  for name in $dns_records; do
    if [[ "$name" != *.* ]]; then
      name="${name}."
    fi
    dns_names="${dns_names}${name} "
  done
  dns_names=$(echo "$dns_names" | sed 's/ $//')  # Remove trailing space

  # Calculate spacing to align comment at column 23
  base="- $ip"
  pad_length=$((23 - ${#base}))
  if (( pad_length < 1 )); then
    pad_length=1
  fi
  padding=$(printf '%*s' "$pad_length")

  if [[ -n "$dns_names" ]]; then
    echo "${base}${padding}#  $dns_names"
  else
    echo "$base"
  fi
done < "$input_file"
