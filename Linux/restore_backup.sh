#!/bin/bash
# Restore Backup
LOGFILE="/logs/phase1_restore.log"
BACKUP_DIR="/backup/initial"

echo "[*] Starting backup restoration at $(date)" | tee -a "$LOGFILE"

BACKUP_FILE=$(ls -t "$BACKUP_DIR" | head -n 1)

if [[ -z "$BACKUP_FILE" ]]; then
    echo "[X] No backup file found in $BACKUP_DIR!" | tee -a "$LOGFILE"
    exit 1
fi

echo "[*] Found latest backup: $BACKUP_FILE" | tee -a "$LOGFILE"

tar -xzvf "$BACKUP_DIR/$BACKUP_FILE" -C / | tee -a "$LOGFILE"

if [[ $? -eq 0 ]]; then
    echo "[✔] Backup restored successfully!" | tee -a "$LOGFILE"
else
    echo "[X] Backup restoration failed!" | tee -a "$LOGFILE"
    exit 1
fi
