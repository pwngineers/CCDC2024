#!/usr/bin/env bash 
cd "$(dirname "$0")"
bash ./obfuscate_ports.sh
bash ./disable_users.sh
bash ./monitor_backup.sh
bash ./kill_shells.sh
