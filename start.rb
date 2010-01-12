#!/usr/bin/ruby
# This script will ask the user a set of questions inorder to setup the frontend node 
# of the Clusting enviorment
#
# Jacob Atkins
# Univerisity of Virginia's College at Wise
#
# jta4j@mcs.uvawise.edu

require 'yaml'

system("clear") # Lets start with a clean slate

puts "This script will install several tools that are needed to run WiseLinux."
puts "It will also configure your system for usage as a master node in a Cluster."
puts "\n"
puts "If there is an older config.yml file it will be overwritten."
puts "Exit now and back it up if you wish to save it."
puts "\n"
puts "To continue press Enter\\Return to exit press ctrl+c ..."

gets # Waiting for enter to be hit

f = File.open("config.yml", 'w') # Open the config file after the user has contiuned

puts "Rebuilding the system will optimize all under laying programs."
puts "This task isn't required but is highly recomended."
puts "\n"
puts "Would you like to rebuild the system? [Y/n]"

system = gets.chomp.upcase

# TODO There has to be a better way to write the config file rather than doing each little section at a time.
# Start of the world rebuild
while system != "Y" || system != "N"
  if system == ""
    system = "Y"
  end
  if system == "Y"
    puts "The System will be rebuilt."
    config = { :world => { :rebuild => true } } 
    break
  elsif system == "N"
    puts "The System will not be rebuild."
    config = { :world => { :rebuild => false } }
    break
  else
    puts "Please enter y or n..."
    system = gets.chomp.upcase
  end
end

f.puts config.to_yaml # Write this section the file

puts "\nWhat network device is pointing to the cluster?"

lan_nic = gets.chomp

puts "\nThe cluster will need a private subnet."
puts "What will this range be? ex [192.168.0.0/16]"

lan_subnet_range = gets.chomp

puts "\nWhat will be the IP address of the network device pointing to the cluster?"

lan_ip = gets.chomp

config = { :lan => { :nic => lan_nic, :subnet => lan_subnet_range, :ip => lan_ip } }

f.puts config.to_yaml

# TODO Create real page with instructions on downloading MAUI
puts "\n\nIt is recommended that you install the MAUI Cluster Scheduler."
puts "MAUI is free but has to be downladed indepently, instructions"
puts "on downloading MAUI can be found at http://something.com/wiki/maui"
puts "\n"
puts "Please enter the URL for your copy of MAUI or press enter to contiune without it..."

maui_url = gets.chomp

# TODO There needs to be a url validater here so that the script doesn't shit its pants down the road.
config = { :maui => { :url => maui_url } }

f.puts config.to_yaml

system(`clear`)

puts "Starting the install..."

`scripts/01_world.rb`
