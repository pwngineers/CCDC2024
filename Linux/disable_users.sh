#!/usr/bin/env bash 

LOGFILE="/logs/phase1_step3.log"
for user in $(awk -F: '$3>=1000 {print $1}' /etc/passwd); do
    sudo usermod -s /usr/sbin/nologin "$user"
done

pkill -u $(awk -F: '$3>=1000 {print $1}' /etc/passwd)

for user in $(who | awk '{print $1}' | grep -v root | sort -u); do
    sudo pkill -u "$user"
done

echo "[✔] Users logins purged" | tee -a "$LOGFILE"
