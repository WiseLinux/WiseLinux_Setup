#!/usr/bin/ruby
# This script will rebuild world and system
# Jacob Atkins
# Univerisity of Virginia's College at Wise
#
# jta4j@mcs.uvawise.edu

puts "Rebuilding the system will optimize all under laying programs"
puts "This task isn't required but is highly recomended."
puts "\n"
puts "Would you like to rebuild the system? [Y/n]"

rebuild = gets.chomp

while rebuild.upcase != "Y" || rebuild.upcase != "N"

  if rebuild.upcase == "Y"
    puts 'Building world'

    `emerge -e world`

    puts 'Building system'
    `emerge -e system`
  elsif rebuild.upcase == "N"
    puts 'Moving to next step.'
  else
    puts "#{rebuild} is an option, please enter y or n"
  end
end

