#!/usr/bin/env bash
set -euo pipefail

# ---------------- CONFIG ----------------

SSH_DEFAULT_PORTS=("22")
STATE_FILE="/var/tmp/ssh_egress_state"

# Whitelist format:
# CIDR_or_IP:PORT
WHITELIST=(
  "192.168.0.0/16:22"
  "10.0.0.5:2222"
)

# ----------------------------------------

HOSTNAME="$(hostname)"
TIMESTAMP="$(date -Is)"

touch "$STATE_FILE"

is_whitelisted() {
  local ip="$1"
  local port="$2"

  for entry in "${WHITELIST[@]}"; do
    local net="${entry%:*}"
    local wport="${entry##*:}"

    [[ "$port" != "$wport" ]] && continue

    if python3 - <<EOF 2>/dev/null
import ipaddress
print(ipaddress.ip_address("$ip") in ipaddress.ip_network("$net", strict=False))
EOF
    then
      return 0
    fi
  done
  return 1
}

already_logged() {
  local key="$1"
  grep -Fxq "$key" "$STATE_FILE"
}

mark_logged() {
  echo "$1" >> "$STATE_FILE"
}

extract_proc_info() {
  local pid="$1"

  local user exe cmdline

  user="$(ps -o user= -p "$pid" 2>/dev/null | awk '{print $1}')"
  exe="$(readlink -f /proc/$pid/exe 2>/dev/null || true)"
  cmdline="$(tr '\0' ' ' < /proc/$pid/cmdline 2>/dev/null || true)"

  echo "$user|$exe|$cmdline"
}

# ---------------- MAIN ----------------

ss -pt state established | tail -n +2 | while read -r line; do
  remote="$(awk '{print $5}' <<<"$line")"
  procinfo="$(sed -n 's/.*users:(\(.*\))/\1/p' <<<"$line")"

  [[ "$remote" != *:* ]] && continue

  rip="${remote%:*}"
  rport="${remote##*:}"

  ssh_port_match=0
  for p in "${SSH_DEFAULT_PORTS[@]}"; do
    [[ "$rport" == "$p" ]] && ssh_port_match=1
  done

  ssh_proc_match=0
  [[ "$procinfo" == *ssh* ]] && ssh_proc_match=1

  (( ssh_port_match == 0 && ssh_proc_match == 0 )) && continue

  is_whitelisted "$rip" "$rport" && continue

  pid="$(sed -n 's/.*pid=\([0-9]\+\).*/\1/p' <<<"$procinfo")"
  [[ -z "$pid" ]] && continue

  key="${rip}:${rport}:${pid}"
  already_logged "$key" && continue

  IFS="|" read -r user exe cmdline < <(extract_proc_info "$pid")

  logger -p auth.warning \
    "Outbound SSH detected host=$HOSTNAME dest=$rip:$rport pid=$pid user=$user exe=$exe cmdline=\"$cmdline\""

  mark_logged "$key"
done
