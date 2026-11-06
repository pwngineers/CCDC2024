#!/usr/bin/env bash 
LOGFILE="/logs/phase1_step2.log"
echo "[*] Disable sshd ..." | tee -a "$LOGFILE"
systemctl stop sshd
systemctl disable sshd

echo "[✔] SSH disabled" | tee -a "$LOGFILE"

