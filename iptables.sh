#!/bin/sh

LAN=$1
WAN=$2

LAN_SUBNET=$3

iptables -F
iptables -t nat -F

iptables -P INPUT ACCEPT
iptables -P OUTPUT ACCEPT
iptables -P FORWARD DROP

iptables -I INPUT 1 -i ${LAN} -j ACCEPT
iptables -I INPUT 1 -i lo -j ACCEPT
iptables -A INPUT -p UDP --dport bootps ! -i ${LAN} -j REJECT
iptables -A INPUT -p UDP --dport domain ! -i ${LAN} -j REJECT

iptables -A INPUT -p TCP --dport ssh -i ${WAN} -j ACCEPT

iptables -A INPUT -p TCP ! -i ${LAN} -d 0/0 --dport 0:1023 -j DROP
iptables -A INPUT -p UDP ! -i ${LAN} -d 0/0 --dport 0:1023 -j DROP

iptables -I FORWARD -i ${LAN} -d ${LAN_SUBNET} -j DROP
iptables -A FORWARD -i ${LAN} -s ${LAN_SUBNET} -j ACCEPT
iptables -A FORWARD -i ${WAN} -d ${LAN_SUBNET} -j ACCEPT
iptables -t nat -A POSTROUTING -o ${WAN} -j MASQUERADE

# Tell the kernel that ip forwarding is OK
	echo 1 > /proc/sys/net/ipv4/ip_forward
	for f in /proc/sys/net/ipv4/conf/*/rp_filter ; do echo 1 > $f ; done

/etc/init.d/iptables save > /dev/null 2>&1
rc-update add iptables default > /dev/null 2>&1

sed -i -e 's/#net\.ipv4\.ip_forward.*/net.ipv4.ip_forward = 1/' /etc/sysctl.conf
sed -i -e 's/#net\.ipv4\.conf\.default\.rp_filter.*/net.ipv4.conf.default.rp_filter = 1/' /etc/sysctl.conf
sed -i -e 's/net\.ipv4\.conf\.default\.rp_filter.*/net.ipv4.conf.default.rp_filter = 1/' /etc/sysctl.conf