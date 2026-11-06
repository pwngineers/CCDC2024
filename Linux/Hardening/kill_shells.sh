#!/usr/bin/env bash 
# Kill Unauthorized Remote Shells (Only Preserve Current and Parent Shell)
LOGFILE="/logs/phase1_step1.log"

echo "[*] Checking for remote shell sessions..." | tee -a "$LOGFILE"

MY_PID=$$
PARENT_PID=$(ps -o ppid= -p $$ | awk 'NR==2 {print $1}')

ps aux | grep -E "nc|bash|perl|python|sh" | grep -v grep | while read -r line; do
    PID=$(echo "$line" | awk '{print $2}')
    PPID=$(ps -o ppid= -p "$PID" | awk 'NR==2 {print $1}')

    if [[ "$PID" != "$MY_PID" && "$PID" != "$PARENT_PID" ]]; then
        echo "[!] Killing unauthorized shell: PID $PID (Parent: $PPID)" | tee -a "$LOGFILE"
        kill -9 "$PID"
    fi
done

echo "[✔] Remote shells terminated (Only current shell and parent remain)" | tee -a "$LOGFILE"
