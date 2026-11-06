#!/usr/bin/env bash
# If possible, ask judge about changing smpt and pop3 port to more secure version
echo "Be sure to check if the port policy on the script pertains to your use"
iptables -F
iptables -P INPUT DROP

iptables -A INPUT -p tcp --dport 25 -j ACCEPT
iptables -A INPUT -p tcp --dport 110 -j ACCEPT
# iptables -A INPUT -p tcp --dport 80 -j ACCEPT
# ==
iptables -N LOG_AND_DROP
iptables -A LOG_AND_DROP -j LOG --log-prefix "Port Scan: " --log-level 4
iptables -A LOG_AND_DROP -j DROP
iptables -A INPUT -p tcp --dport 22 -m state --state NEW -m recent --set
iptables -A INPUT -p tcp --dport 22 -m state --state NEW -m recent --update --seconds 60 --hitcount 10 -j LOG_AND_DROP
iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP
iptables -A INPUT -p tcp --tcp-flags SYN,FIN SYN,FIN -j DROP
iptables -A INPUT -p tcp --tcp-flags SYN,RST SYN,RST -j DROP
iptables -A INPUT -p tcp --tcp-flags FIN,RST FIN,RST -j DROP
iptables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP
iptables -A INPUT -p tcp --tcp-flags ALL NONE -j LOG --log-prefix "NULL Scan: "
iptables -A INPUT -p tcp --tcp-flags ALL ALL -j LOG --log-prefix "XMAS Scan: "

echo "DONE"
