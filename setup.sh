#!/bin/bash

# Which network card is facing which network

lan_ethernet = "eth0" # This is for the interface that will connect to the cluster
wan_ethernet = "eth1" # This is for the interface that will connect to your network

# IP addresses that will be used

lan_subnet = "192.168.0.0\\24"	 # The subnet that you want for the cluster network
lan_ip_address = "192.168.0.1"	 # The IP address of the master node on the cluster network

wan_ip_address = "143.60.60.27"	 # The IP address of the master node on your network; if you use DHCP for this type dhcp in the quotes

# Name servers that you would like to use
# By Default the nameservers are set to OpenDNS
name_server[0] = "208.67.222.222"
name_server[1] = "208.67.220.220"
name_server[2] = ""
name_server[3] = ""

# MAUI Cluster Scheduler URL
# In order to install MAUI, you need to download it and place it in a location that is accesiable by wget

maui_url = "http://www.example.com/maui.tar.gz"

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

# Get the count of cores in the system
num_cores=`grep 'core id' /proc/cpuinfo | sort -u | wc -l`

if [ $num_cores -eq 0 ]; then
  # this box is either an old SMP or single-CPU box, so count the # of processors
  num_cores=`grep '^processor' /proc/cpuinfo | sort -u | wc -l`
fi

echo "MAKEOPTS=\"-j$(($num_cores+1))\"" >> /etc/make.conf
echo "USE=\"-* 3dnow gpm mmx ncurses pam sse tcpd fortran perl ruby\"" >> /etc/make.conf

mkdir /etc/portage
mkdir ./log

echo "dev-util/git threads bash-compleation" >> /etc/portage/package.use
echo "dev-lang/ruby rubytests threads" >> /etc/portage/package.use
echo "dev-ruby/rubygems -doc -server" >> /etc/portage/package.use
echo "sys-cluster/torque server" >> /etc/portage/package.use
echo "sys-cluster/openmpi pbs" >> /etc/portage/package.use

emerge --sync 1> log/portage_sync.log 2> log/portage_sync.err.log &
echo -n "Syncing portage... "
spinner $!

echo

emerge -euND system 1> log/system_rebuild.log 2> log/system_rebuild.err.log &
echo -n "Rebuilding system... "
spinner $!

echo

emerge -euND world 1> log/world_rebuild.log 2> log/system_rebuild.err.log &
echo -n "Rebuilding world... "
spinner $!

echo

emerge sys-cluster/torque sys-cluster/openmpi net-fs/nfs-utils net-firewall/iptables 1> log/cluster.log 2> log/cluster.err.log &
echo -n "Installing torque, openmpi, nfs-utils, and iptables..."
spinner $!

echo "Taking a 30 second sleep..."
sleep 30

emerge dev-util/git dev-lang/ruby dev-ruby/rubygems 1> log/packages.log 2> log/packages.err.log &
echo -n "Installing git, ruby, and rubygems... "
spinner $!

echo

gem install --no-ri --no-rdoc highline 1> log/gem.log 2> log/gem.err.log &
