#!/usr/bin/env bash
echo "Be sure to check if the port policy on the script pertains to your use"

iptables -F
iptables -P INPUT DROP

# ESSENTIAL: Allow loopback
iptables -A INPUT -i lo -j ACCEPT

# ESSENTIAL: Allow established/related connections (responses to your outbound traffic)
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Allow ICMP (ping) - needed for network troubleshooting
iptables -A INPUT -p icmp -j ACCEPT

# Services
# iptables -A INPUT -p tcp --dport 22 -j ACCEPT   # SSH
# iptables -A INPUT -p tcp --dport 25 -j ACCEPT   # SMTP
# iptables -A INPUT -p tcp --dport 110 -j ACCEPT  # POP3
iptables -A INPUT -p tcp --dport 80 -j ACCEPT # HTTP

# Port scan detection chain
iptables -N LOG_AND_DROP
iptables -A LOG_AND_DROP -j LOG --log-prefix "Port Scan: " --log-level 4
iptables -A LOG_AND_DROP -j DROP

# SSH brute force protection
iptables -A INPUT -p tcp --dport 22 -m state --state NEW -m recent --set
iptables -A INPUT -p tcp --dport 22 -m state --state NEW -m recent --update --seconds 60 --hitcount 10 -j LOG_AND_DROP

# Block and log malformed packets
iptables -A INPUT -p tcp --tcp-flags ALL NONE -j LOG --log-prefix "NULL Scan: "
iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP
iptables -A INPUT -p tcp --tcp-flags ALL ALL -j LOG --log-prefix "XMAS Scan: "
iptables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP
iptables -A INPUT -p tcp --tcp-flags SYN,FIN SYN,FIN -j DROP
iptables -A INPUT -p tcp --tcp-flags SYN,RST SYN,RST -j DROP
iptables -A INPUT -p tcp --tcp-flags FIN,RST FIN,RST -j DROP

echo "DONE"