#!/usr/bin/ruby
# This script will rebuild world and system
# it will also install all software that is
# required to run a bare bones cluster.
#
# Jacob Atkins
# Univerisity of Virginia's College at Wise
#
# jta4j@mcs.uvawise.edu

require 'yaml'
 
CONFIG = YAML::load(File.read('config.yml'))

if CONFIG['world']['rebuild'] == true
  puts 'Syncing the portage tree...'
  `emerge --sync > log/portage_sync.log`
  
  puts 'Rebuilding the system...'
  `emerge -e system > log/system_rebuild.log`
  
  puts 'Rebuilding the world...'
  `emerge -e world > log/world_rebuild.log`
end

puts 'Installing openMPI, torque, and nfs-utils'

`echo sys-cluster/torque server >> /etc/portage/pakage.use`
`echo sys-cluster/openmpi pbs >> /etc/portage/package.use`

`emerge openmpi torque nfs-utils`

