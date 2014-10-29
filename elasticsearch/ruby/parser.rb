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
  opts.on("-p","--port PORT",Integer, "Elasticsearch port number") do |p|
    options[:port] = p
  end
  opts.on("-h","--host HOST",String, "Elasticsearch host") do |h|
    options[:host] = h
  end
  opts.on("-s","--snapshot create/delete snapshot_name",[:create,:delete], "Elasticsearch port number") do |a,n|
    options[:action] = a
    options[:snapname] = n
  end
end.parse!

p options
p ARGV
