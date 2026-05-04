#!/usr/bin/env bash

set -euo pipefail

MAX_HANDSHAKE_AGE=180

# default = fail closed
output() {
  local alt="$1"
  local text="${2:-}"

  if [[ -n "$text" ]]; then
    echo "{\"alt\":\"$alt\", \"text\":\"$text\"}"
  else
    echo "{\"alt\":\"$alt\"}"
  fi

  exit 0
}

# Capture wg output
wg_output="$(sudo wg show)"

# Extract interface name
INTERFACE="$(printf "%s\n" "$wg_output" | awk '/^interface:/{print $2; exit}')"

# Check if we got an interface
if [[ -z "$INTERFACE" ]]; then
    output "down" "(unprotected)"
    exit 0
fi


try() {
  "$@" 2>/dev/null
}

# 1. Interface exists and is up
link=$(try ip link show "$INTERFACE") || output "down" "(unprotected)"

if ! grep -q "UP" <<< "$link"; then
  output "down" "(unprotected)"
fi

# 2. WireGuard handshake must exist and be recent
handshake=$(try sudo wg show "$INTERFACE" latest-handshakes | awk '{print $2}')

if [[ -z "${handshake:-}" || "$handshake" -eq 0 ]]; then
  output "down" "(unprotected)"
fi

now=$(date +%s)
age=$((now - handshake))

if (( age > MAX_HANDSHAKE_AGE )); then
  output "stale" "(stale)"
fi


if ! ping -c 1 -W 1 1.1.1.1 >/dev/null 2>&1; then
  output "offline" "(offline)"
fi

# 3. IPv4 routing must go via WG
route4=$(try ip route get 1.1.1.1)

if ! grep -q "dev $INTERFACE" <<< "$route4"; then
  output "leak" "(leaking)"
fi

# 4. IPv6 routing must go via WG (if present)
if try ip -6 route get 2606:4700:4700::1111 >/dev/null; then
  route6=$(ip -6 route get 2606:4700:4700::1111 2>/dev/null || true)
  if ! grep -q "dev $INTERFACE" <<< "$route6"; then
    output "leak" "(leaking)"
  fi
fi

# If all checks pass
output "up" "($INTERFACE)"
