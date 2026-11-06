#!/bin/bash

# Khai (Created Winter 2024)

# Script for setting up basic security for linux servers using iptables 
# DEBIAN systems only!

print () {
  echo "====================================================="
  echo $1
  echo "====================================================="
}

print "Step 1: Pulling dependencies"
#any relevant wget and installs goes here


#apt install iptables-persistent -y
apt-get install iptables-extentions
echo "done"

print "Step 2: Flushing current rules and adding new ones"


#flushing current rules
/sbin/iptables -F

print "portscan countermeasures"

/sbin/iptables -A INPUT -p tcp --tcp-flags SYN,ACK SYN -m state --state NEW -j DROP
/sbin/iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP
/sbin/iptables -A INPUT -p tcp --tcp-flags ACK,RST RST -j DROP
/sbin/iptables -A INPUT -p tcp --tcp-flags ACK,FIN FIN -j DROP
/sbin/iptables -A INPUT -p tcp --tcp-flags ACK,URG URG -j DROP
/sbin/iptables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP

/sbin/iptables -A INPUT -p tcp --tcp-flags ALL NONE -m hashlimit --hashlimit-upto 7/m --hashlimit-burst 7 --hashlimit-mode srcip --hashlimit-name limit_tcp_flags -j ACCEPT

/sbin/iptables -A INPUT -p tcp --tcp-flags SYN,ACK,FIN,RST RST -m hashlimit --hashlimit-upto 1/second --hashlimit-burst 2 --hashlimit-mode srcip --hashlimit-name limit_flags -j RETURN



echo "DONE"

print "blocking sus ip"

/sbin/iptables -A INPUT -p tcp -m state --state NEW -m recent --name portscan --set iptables -A INPUT -p tcp -m state --state NEW -m recent --name portscan --seconds 60 --hitcount 10 -j DROP

/sbin/iptables -A INPUT -p icmp --icmp-type port-unreachable -j DROP

print "logging"
/sbin/iptables -A INPUT -p tcp --tcp-flags SYN,ACK,FIN,RST RST -j LOG --log-prefix "Nmap Scan Detected: "

/sbin/iptables -A INPUT -m limit --limit 5/min -j LOG

/sbin/iptables -A INPUT --state new -m recent --set

#avoid hampering legit traffic
/sbin/iptables -A INPUT -p tcp --syn -m limit --limit 1/s --limit-burst 5 -j ACCEPT iptables -A INPUT -p tcp --syn -j DROP

#whitelists
# iptables -A INPUT -s [ip addr] -j ACCEPT


#dos attacks
# https://gist.github.com/mattia-beta/bd5b1c68e3d51db933181d8a3dc0ba64

### 1: Drop invalid packets ### 
/sbin/iptables -t mangle -A PREROUTING -m conntrack --ctstate INVALID -j DROP  

### 2: Drop TCP packets that are new and are not SYN ### 
/sbin/iptables -t mangle -A PREROUTING -p tcp ! --syn -m conntrack --ctstate NEW -j DROP 
 
### 3: Drop SYN packets with suspicious MSS value ### 
/sbin/iptables -t mangle -A PREROUTING -p tcp -m conntrack --ctstate NEW -m tcpmss ! --mss 536:65535 -j DROP  

### 4: Block packets with bogus TCP flags ### 
#/sbin/iptables -t mangle -A PREROUTING -p tcp --tcp-flags FIN,SYN FIN,SYN -j DROP
#/sbin/iptables -t mangle -A PREROUTING -p tcp --tcp-flags SYN,RST SYN,RST -j DROP
#/sbin/iptables -t mangle -A PREROUTING -p tcp --tcp-flags FIN,RST FIN,RST -j DROP
#/sbin/iptables -t mangle -A PREROUTING -p tcp --tcp-flags FIN,ACK FIN -j DROP
#/sbin/iptables -t mangle -A PREROUTING -p tcp --tcp-flags ACK,URG URG -j DROP
#/sbin/iptables -t mangle -A PREROUTING -p tcp --tcp-flags ACK,PSH PSH -j DROP
#/sbin/iptables -t mangle -A PREROUTING -p tcp --tcp-flags ALL NONE -j DROP

### 5: Block spoofed packets ### 
/sbin/iptables -t mangle -A PREROUTING -s 224.0.0.0/3 -j DROP 
/sbin/iptables -t mangle -A PREROUTING -s 169.254.0.0/16 -j DROP 
/sbin/iptables -t mangle -A PREROUTING -s 172.16.0.0/12 -j DROP 
/sbin/iptables -t mangle -A PREROUTING -s 192.0.2.0/24 -j DROP 
/sbin/iptables -t mangle -A PREROUTING -s 192.168.0.0/16 -j DROP 
/sbin/iptables -t mangle -A PREROUTING -s 10.0.0.0/8 -j DROP 
/sbin/iptables -t mangle -A PREROUTING -s 0.0.0.0/8 -j DROP 
/sbin/iptables -t mangle -A PREROUTING -s 240.0.0.0/5 -j DROP 
/sbin/iptables -t mangle -A PREROUTING -s 127.0.0.0/8 ! -i lo -j DROP  

### 7: Drop fragments in all chains ### 
/sbin/iptables -t mangle -A PREROUTING -f -j DROP  

### 8: Limit connections per source IP ### 
/sbin/iptables -A INPUT -p tcp -m connlimit --connlimit-above 111 -j REJECT --reject-with tcp-reset  

### 9: Limit RST packets ### 
/sbin/iptables -A INPUT -p tcp --tcp-flags RST RST -m limit --limit 2/s --limit-burst 2 -j ACCEPT 
/sbin/iptables -A INPUT -p tcp --tcp-flags RST RST -j DROP  

### 10: Limit new TCP connections per second per source IP ### 
/sbin/iptables -A INPUT -p tcp -m conntrack --ctstate NEW -m limit --limit 60/s --limit-burst 20 -j ACCEPT 
/sbin/iptables -A INPUT -p tcp -m conntrack --ctstate NEW -j DROP  

### 11: Use SYNPROXY on all ports (disables connection limiting rule) ### 
# Hidden - unlock content above in "Mitigating SYN Floods With SYNPROXY" section

### SSH brute-force protection ### 
/sbin/iptables -A INPUT -p tcp --dport ssh -m conntrack --ctstate NEW -m recent --set 
/sbin/iptables -A INPUT -p tcp --dport ssh -m conntrack --ctstate NEW -m recent --update --seconds 60 --hitcount 10 -j DROP  

###SYNPROXY
/sbin/iptables -t raw -A PREROUTING -p tcp -m tcp --syn -j CT --notrack 
/sbin/iptables -A INPUT -p tcp -m tcp -m conntrack --ctstate INVALID,UNTRACKED -j SYNPROXY --sack-perm --timestamp --wscale 7 --mss 1460 
/sbin/iptables -A INPUT -m conntrack --ctstate INVALID -j DROP

#metasploitable patch
/sbin/iptables -A INPUT -p tcp --dport 445 -j DROP
/sbin/iptables -A INPUT -p udp --dport 445 -j DROP


#any other unused ports should be blocked here


#Todo: Hardern NFS, PostgressSQL, MySQL, and any other backdoors

echo "DONE."
print "Remember to add additional rules and finalize iptables"
