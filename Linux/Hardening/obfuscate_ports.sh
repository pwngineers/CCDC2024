#!/usr/bin/env bash 

# Nmap obfuscation
LOGFILE="/logs/phase1_step4.log"
iptables -F
echo "[*] Deploying Nmap countermeasures..." | tee -a "$LOGFILE"

echo "[*] rate limit ICMP (ping) requests..." | tee -a "$LOGFILE"
iptables -A INPUT -p icmp --icmp-type echo-request -m limit --limit 1/second -j ACCEPT
iptables -A INPUT -p icmp --icmp-type echo-request -j DROP


for PORT in {1024..1035}; do
    iptables -A INPUT -p tcp --dport $PORT -j REJECT --reject-with tcp-reset
done

# Modify Service Banners
FAKE_BANNERS=(
    "Welcome to McDonald's Secure Checkout Terminal"
    "NASA Deep Space Network Gateway - AUTHORIZED PERSONNEL ONLY"
    "IBM AS/400 Secure Payroll Database"
    "PostgreSQL 14.2 (Top Secret/SCI Clearance Required)"
    "220 NORAD Mail Relay v7.2 - Authorized Users Only"
    "5.7.41-Quantum AI Database (DoD Research Node)"
    "Elasticsearch v8.2.1 (Walmart Inventory AI Node)"
    "* OK Dovecot v3.2 (NSA SIGINT Relay - Level 6 Clearance Only)"
    "Apache/2.4.48 (Windows 95 Secure Embedded Edition)"
    "SSH-2.0-XTS-400 Secure Gateway v3.2 (Lockheed Martin)"
)

RANDOM_BANNER=${FAKE_BANNERS[$RANDOM % ${#FAKE_BANNERS[@]}]}

# Modify SSH banner
if [[ -f /etc/ssh/sshd_config ]]; then
    echo "Banner /etc/issue.net" >> /etc/ssh/sshd_config
    echo "$RANDOM_BANNER" > /etc/issue.net
    systemctl restart sshd 2>/dev/null || echo "[!] SSH service not found, skipping..." | tee -a "$LOGFILE"
fi

# Modify Apache banner if running
if systemctl is-active --quiet apache2; then
    echo "ServerTokens Full" >> /etc/apache2/apache2.conf
    echo "ServerSignature On" >> /etc/apache2/apache2.conf
    echo "ErrorDocument 404 '<h1>$RANDOM_BANNER</h1>'" > /var/www/html/404.html
    systemctl restart apache2 2>/dev/null || echo "[!] Apache2 not found, skipping..." | tee -a "$LOGFILE"
fi

# Modify SMTP banners (Dovecot & Postfix)
if systemctl is-active --quiet dovecot; then
    echo "mail_version_string = $RANDOM_BANNER" >> /etc/dovecot/conf.d/10-ssl.conf
    systemctl restart dovecot 2>/dev/null || echo "[!] Dovecot not found, skipping..." | tee -a "$LOGFILE"
fi

if systemctl is-active --quiet postfix; then
    echo "smtpd_banner = $RANDOM_BANNER" >> /etc/postfix/main.cf
    systemctl restart postfix 2>/dev/null || echo "[!] Postfix not found, skipping..." | tee -a "$LOGFILE"
fi

# Fake OS Fingerprint 
FAKE_OS=(
    "Windows 95" 
    "QuantumLink OS v3.2 (Q-Level Restricted)" 
    "TI-84 Graphing Calculator" 
    "Red Star OS"
    "AmogOS"
    "CP/M 2.2 Government Edition"
    "Stratus VOS v18.0 (Pentagon Comms Gateway)"
    "Valve SteamOS v0.2 Alpha (Half-Life 3 Ready)"
    "Skynet AI Core v4.2"
    "MS-DOS 6.22 Internet Server"
    "Solaris 1.0 (1992)"
    "XTS-400 Secure UNIX (Lockheed-Martin Proprietary Build)"
    "VAX/VMS 7.2 Secure Rebuild (US DoE Labs)"
    )
RANDOM_OS=${FAKE_OS[$RANDOM % ${#FAKE_OS[@]}]}

echo "[*] Deploying fake OS fingerprint: $RANDOM_OS" | tee -a "$LOGFILE"
iptables -t mangle -A OUTPUT -p icmp -j TTL --ttl-set $((RANDOM % 50 + 100))
iptables -t mangle -A POSTROUTING -j TTL --ttl-set $((RANDOM%5+60))
iptables -t mangle -A POSTROUTING -p tcp -j TCPMSS --set-mss $((RANDOM%50+1400))
iptables -A OUTPUT -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --set-mss 1448
iptables -A INPUT -p icmp --icmp-type address-mask-request -j DROP
iptables -A INPUT -p icmp --icmp-type timestamp-request -j DROP

iptables -A INPUT -p tcp --dport 25 -j ACCEPT  # Postfix (SMTP)
iptables -A INPUT -p tcp --dport 110 -j ACCEPT # POP3 (Dovecot)

iptables -A INPUT -p tcp --dport 8000 -j ACCEPT  # Splunk Web UI
iptables -A INPUT -p tcp --dport 9997 -j ACCEPT  # Splunk Forwarding

echo "[✔] Nmap obfuscation applied." | tee -a "$LOGFILE"
