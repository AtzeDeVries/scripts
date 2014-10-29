#!/usr/bin/ruby
require 'optparse'

options = {}
options[:host] = 'localhost'
options[:port] = '2005'
OptionParser.new do |opts|
  opts.banner = "Usage: example.rb [options]"

  opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
    options[:verbose] = v
  end
  opts.on("--port P",Integer, "Elasticsearch port number") do |p|
    options[:port] = p
  end
  opts.on("--host H",String, "Elasticsearch port number") do |h|
    options[:host] = h
  end
end.parse!

p options
p ARGV
