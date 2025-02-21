#!/usr/bin/env bash 

# Initial Backup & Directory Monitoring Setup
LOGFILE="/logs/phase1_step4.log"
BACKUP_DIR="/backup/initial"
AUDIT_RULES_FILE="/etc/audit/rules.d/cadia.rules"

echo "[*] Starting backup and monitoring setup at $(date)" | tee -a "$LOGFILE"
mkdir -p "$BACKUP_DIR"

BACKUP_FILE="$BACKUP_DIR/backup_$(date +%F_%H-%M-%S).tar.gz"
echo "[*] Creating backup: $BACKUP_FILE" | tee -a "$LOGFILE"
tar --exclude=/proc --exclude=/sys --exclude=/dev --exclude=/run \
    -czvf "$BACKUP_FILE" /etc /opt /var/www | tee -a "$LOGFILE"

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

systemctl enable --now auditd | tee -a "$LOGFILE"

echo "[*] Setting up audit rules..." | tee -a "$LOGFILE"
cat <<EOF > "$AUDIT_RULES_FILE"
-w /etc/ -p wa -k cadia_watch
-w /opt/ -p wa -k cadia_watch
-w /var/www/ -p wa -k cadia_watch
EOF

systemctl restart auditd

augenrules --load | tee -a "$LOGFILE"

echo "[✔] Directory monitoring enabled for /etc/, /opt/, and /var/www/" | tee -a "$LOGFILE"

