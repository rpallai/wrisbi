#!/usr/bin/env ruby
Dir.chdir(File.dirname(File.dirname($0)))
require 'yaml'
require 'active_resource'
require './models/transaction'

files = ARGV
if files.length.zero?
  puts "Usage: #{$0} <yaml_file> [yaml_file ...]"
  exit 1
end

files.each do |file|
  yaml_transaction = YAML.load(open(file).read)
  Transaction.include_root_in_json = true
  transaction = Transaction.new(yaml_transaction)

  transaction.date = Date.today

  unless transaction.save
    puts "Error importing '#{file}':", transaction.errors.full_messages
  else
    puts "'#{file}' imported"
  end
end
