#!/usr/bin/ruby
# This script will ask the user a set of questions inorder to setup the frontend node 
# of the Clusting enviorment
#
# Jacob Atkins
# Univerisity of Virginia's College at Wise
#
# jta4j@mcs.uvawise.edu

require 'yaml'

`clear` # Lets start with a clean slate

puts "This script will install several tools that are needed to run WiseLinux."
puts "It will also configure your system for usage as a master node in a Cluster."
puts "\n"
puts "To continue press Enter\\Return..."

gets # Waiting for enter to be hit

puts "Rebuilding the system will optimize all under laying programs."
puts "This task isn't required but is highly recomended."
puts "\n"
puts "Would you like to rebuild the system? [Y/n]"

system = gets.chomp.upcase

while system != "Y" || system != "N"
  if system == "Y"
    puts "The System will be rebuilt."
    world = { :rebuild => true } 
    break
  elsif system == "N"
    puts "The System will not be rebuild."
    world = { :rebuild => false }
    break
  else
    puts "Please enter y or n..."
    system = gets.chomp.upcase
  end
end

File.open("config.yml", 'w') {|f| f.puts world.to_yaml }