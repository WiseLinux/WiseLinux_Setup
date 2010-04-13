#!/bin/bash

# Which network card is facing which network

lan_ethernet="eth0" # This is for the interface that will connect to the cluster
wan_ethernet="eth1" # This is for the interface that will connect to your network

# IP addresses that will be used

	# Cluster network

	lan_subnet="192.168.0.0\\24"	   # The subnet that you want for the cluster network
	lan_ip="192.168.0.1"	 	 # The IP address of the master node on the cluster network
	lan_broadcast="192.168.0.255" # The broadcast address for the lan adapter
	lan_netmask="255.255.255.0"   # Netmask for the lan 

	# Public network - If you want to use dhcp for this, just set the value of wan_ip to dhcp

	wan_ip="10.0.0.1"	 # The IP address of the master node on your network; if you use DHCP for this type dhcp in the quotes
	wan_broadcast="10.0.0.255" 
	wan_netmask="255.255.255.0"

# Name servers that you would like to use
# By Default the nameservers are set to OpenDNS
name_server=( "208.67.222.222" "208.67.220.220" )

# NTP server

ntp_server=( "0.north-america.pool.ntp.org" "1.north-america.pool.ntp.org" "2.north-america.pool.ntp.org" "3.north-america.pool.ntp.org" )

# MAUI Cluster Scheduler URL
# In order to install MAUI, you need to download it and place it in a location that is accesiable by wget

maui_url="http://www.example.com/maui.tar.gz"


# Package rebuild
# To make WiseLinux customized for your system you should leave these set to true, but if you don't care change them to false
# the install will be faster.  But your server will not be optimized!!

rebuild_system=true
rebuild_world=true





##################################################################################################################
#  DO NOT EDIT BELOW THIS LINE
##################################################################################################################

spinner(){
PROC=$1
while [ -d /proc/$PROC ];do
echo -ne '/\x08' ; sleep 0.05
echo -ne '-\x08' ; sleep 0.05
echo -ne '\\\x08' ; sleep 0.05
echo -ne '|\x08' ; sleep 0.05
done
return 0
}

if [ ! -e ./log/.stage1 ]; then

	# Get the count of cores in the system
	num_cores=`grep 'core id' /proc/cpuinfo | sort -u | wc -l`

	if [ $num_cores -eq 0 ]; then
		# this box is either an old SMP or single-CPU box, so count the # of processors
		num_cores=`grep '^processor' /proc/cpuinfo | sort -u | wc -l`
	fi

	echo "MAKEOPTS=\"-j$(($num_cores+1))\"" >> /etc/make.conf
	echo "USE=\"-* 3dnow gpm mmx ncurses pam sse tcpd fortran perl ruby\"" >> /etc/make.conf

	if [ ! -d /etc/portage ]; then	
		mkdir /etc/portage
	fi

	if [ ! -d ./log ]; then
		mkdir ./log
	fi

	echo "dev-util/git threads bash-compleation" > /etc/portage/package.use
	echo "dev-lang/ruby rubytests threads" >> /etc/portage/package.use
	echo "sys-cluster/torque server" >> /etc/portage/package.use
	echo "sys-cluster/openmpi pbs" >> /etc/portage/package.use

	touch ./log/.stage1
fi

emerge --sync 1> log/portage_sync.log 2> log/portage_sync.err.log &
echo -n "Syncing portage... "
spinner $!

if [ $rebuild_system == true ]; then

	echo

	emerge -euND system 1> log/system_rebuild.log 2> log/system_rebuild.err.log &
	echo -n "Rebuilding system... "
	spinner $!

fi

if [ $rebuild_world == true ]; then

	echo

	emerge -euND world 1> log/world_rebuild.log 2> log/system_rebuild.err.log &
	echo -n "Rebuilding world... "
	spinner $!

fi

echo

emerge sys-cluster/torque sys-cluster/openmpi net-fs/nfs-utils net-misc/dhcp net-misc/ntp net-firewall/iptables 1> log/cluster.log 2> log/cluster.err.log &
echo -n "Installing torque, openmpi, nfs-utils, dhcp, ntp, and iptables... "
spinner $!

emerge dev-util/git dev-lang/ruby 1> log/packages.log 2> log/packages.err.log &
echo -n "Installing git and ruby... "
spinner $!

echo

echo "Setting the system up... "
echo

echo "# LAN config" > /etc/conf.d/net																			
echo "config_$lan_ethernet=( \"$lan_ip netmask $lan_netmask brd $lan_broadcast\" )" >> /etc/conf.d/net

echo "" >> /etc/conf.d/net
echo "# WAN config" >> /etc/conf.d/net
if [ $wan_ip == "dhcp" ]; then
	echo "config_$wam_ethernet=( \"dhcp\" )" >> /etc/conf.d/net
else
	echo "config_$wan_ethernet=( \"$wan_ip netmask $wan_netmask brd $wan_broadcast\" )" >> /etc/conf.d/net
fi

echo "/home/ *(rw)" > /etc/exports
echo "portmap:$lan_subnet" > /etc/hosts.allow

echo "NTPDATE_WARN=\"n\"" > /etc/conf.d/ntp
echo "NTPDATE_CMD=\"ntpdate\"" >> /etc/conf.d/ntp
echo "NTPDATE_OPTS=\"-b $ntp_server\"" >> /etc/conf.d/ntp

echo "" > /etc/ntp.conf

for server in ${ntp_server[@]}
do
	echo "server $server" >> /etc/ntp.conf
	echo "restrict $server" >> /etc/ntp.conf
done

echo "stratum 10" >> /etc/ntp.conf
echo "driftfile /etc/ntp.drift.server" >> /etc/ntp.conf
echo "logfile /var/log/ntp" >> /etc/ntp.conf
echo "broadcast $lan_broadcast" >> /etc/ntp.conf
echo "restrict default kod" >> /etc/ntp.conf
echo "restrict 127.0.0.1" >> /etc/ntp.conf
echo "restrict $lan_subnet" >> /etc/ntp.conf

ln -s /etc/init.d/net.lo /etc/init.d/net.eth1

rc-update add net.eth0 default
rc-update add net.eth1 default
rc-update add nfs default
rc-update add sshd default
rc-update add ntpd default

wget http://medusa.mcs.uvawise.edu/~jta4j/wiselinux/scripts/iptables.sh

if [ -f iptables.sh ]; then
	chmod +x iptables.sh
else
	exit
fi

iptables.sh $lan_ethernet $wan_ethernet $lan_subnet

