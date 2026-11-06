#!/usr/bin/env bash

# Initial Backup & Directory Monitoring Setup
LOGFILE="/logs/phase1_step4.log"
BACKUP_DIR="/backup/initial"
AUDIT_RULES_FILE="/etc/audit/rules.d/cadia.rules"

LOGDIR="$(dirname "$LOGFILE")"
if [[ ! -d "$LOGDIR" ]]; then
    mkdir -p "$LOGDIR"
fi

if [[ ! -f "$LOGFILE" ]]; then
    touch "$LOGFILE"
fi

echo "[*] Starting backup and monitoring setup at $(date)" | tee -a "$LOGFILE"
mkdir -p "$BACKUP_DIR"

# Build list of directories that actually exist
BACKUP_TARGETS=()
for dir in /etc /opt /var/www; do
    if [[ -d "$dir" ]]; then
        BACKUP_TARGETS+=("$dir")
    else
        echo "[!] Skipping $dir (not found)" | tee -a "$LOGFILE"
    fi
done

BACKUP_FILE="$BACKUP_DIR/backup_$(date +%F_%H-%M-%S).tar.gz"

if [[ ${#BACKUP_TARGETS[@]} -eq 0 ]]; then
    echo "[X] No directories to backup!" | tee -a "$LOGFILE"
    exit 1
fi

echo "[*] Creating backup: $BACKUP_FILE" | tee -a "$LOGFILE"
echo "[*] Backing up: ${BACKUP_TARGETS[*]}" | tee -a "$LOGFILE"
tar --exclude=/proc --exclude=/sys --exclude=/dev --exclude=/run \
    -czvf "$BACKUP_FILE" "${BACKUP_TARGETS[@]}" 2>&1 | tee -a "$LOGFILE"

if [[ $? -eq 0 ]]; then
    echo "[✔] Backup completed successfully!" | tee -a "$LOGFILE"
else
    echo "[X] Backup failed!" | tee -a "$LOGFILE"
    exit 1
fi

if ! command -v auditctl &>/dev/null; then
    echo "[*] Installing auditd..." | tee -a "$LOGFILE"
    apt install -y auditd || yum install -y audit &>> "$LOGFILE"
fi

systemctl enable --now auditd 2>&1 | tee -a "$LOGFILE"

echo "[*] Setting up audit rules..." | tee -a "$LOGFILE"

# Only add audit rules for directories that exist
{
    for dir in /etc /opt /var/www; do
        if [[ -d "$dir" ]]; then
            echo "-w $dir/ -p wa -k cadia_watch"
        else
            echo "# Skipped $dir (not found)" 
        fi
    done
} > "$AUDIT_RULES_FILE"

systemctl restart auditd

augenrules --load 2>&1 | tee -a "$LOGFILE"

echo "[✔] Directory monitoring enabled for existing directories" | tee -a "$LOGFILE"