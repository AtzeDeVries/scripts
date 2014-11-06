#!/usr/bin/ruby

require 'net/http'
require 'uri'
require 'json'
require 'pp'
require 'optparse'

options = {}
options[:host] = 'localhost'
options[:port] = '9200'

OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} [options]"

  opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
    options[:verbose] = v
  end

  opts.on("-p","--port PORT",Integer, "Elasticsearch port number. Default: 9200") do |p|
    options[:port] = p
  end

  opts.on("-h","--host HOST",String, "Elasticsearch host. Default: localhost") do |h|
    options[:host] = h
  end

  opts.on('-s', '--snapshot [snapshotname]', String, 'Create a snapshot.',
    'By default the snapshot name is a timestamp: snapshot-YYYY.MM.dd.HH.SS') do |s|
    options[:snapshot] = s.nil? ? true : s
  end

  opts.on('-r','--repo REPO', String, 'Name of the repository to snapshot/restore to/from',
    'if used without --snapshot or --restore the repository is created') do |r|
    options[:repo] = r
  end

  opts.on('--location LOCATION',String,'File location of the snapshot') do |l|
    options[:repolocation] = l
  end

  opts.on('--restore [snapshotname]', 'Restore from snapshot with [snapshotname]',
    'if no [snapshotname] is given the most recent snapshot is restored') do |r|
    options[:restore] = r.nil? ? true : r
  end

  opts.on('--delete', 'Can be used in combination with --snapshot or --repo',
    'it will delete the snapshot or repository') do |d|
    options[:delete] = d
  end

  opts.on('-l','--list', 'list information about repositories.',
    'if used in combination with --repo snapshot information is shown') do |l|
    options[:list] = l
  end

  opts.on('-i','--index INDEX', String, 'Index to snapshot.',
    'Can be a commaseperated line. If none is given all indexes are snapped') do |l|
    options[:index] = l
  end

  opts.on_tail("--help", "Show this message") do
    puts opts
    exit
  end
end.parse!

def roller(o)

  if not o[:snapshot].nil?
    if not o[:repo].nil?
      if o[:snapshot] == true
        if o[:delete]
          puts 'ERROR: need snaphot name for deletion'
          exit(2)
        else
          puts "taking snap in repository #{o[:repo]}"
          time = Time.now
          stamp = time.strftime("%Y.%m.%d.%H.%M.%S")
          if not o[:index].nil?
            data = { 'indices' => o[:index] }
            snapname = "snapshot-#{o[:index]}-#{stamp}"
          else
            data = {}
            snapname = "snapshot-#{stamp}"
          end
          es_put(o[:host],"_snapshot/#{o[:repo]}/#{snapname}?wait_for_completion=true",data,o[:port],o[:verbose])
        end
      else
        if o[:delete]
          puts "deleting snap with name #{o[:snapshot]} in repository #{o[:repo]}"
          es_delete(o[:host],"_snapshot/#{o[:repo]}/#{o[:snapshot]}?wait_for_completion=true",o[:port],o[:verbose])
        else
          puts "taking snap with name #{o[:snapshot]} in repository #{o[:repo]}"
          if not o[:index].nil?
            data = { 'indices' => o[:index] }
          else
            data = {}
          end
          es_put(o[:host],"_snapshot/#{o[:repo]}/#{o[:snapshot]}?wait_for_completion=true",data,o[:port],o[:verbose])
        end
      end
    else
      puts 'ERROR: cannot take/delete snap, need repo'
      exit(2)
    end

  elsif not o[:restore].nil?
    if not o[:repo].nil?
      if o[:restore] == true
        puts "restoring snap from repository #{o[:repo]}"
        snaps = es_get(o[:host],"_snapshot/#{o[:repo]}/_all",o[:port],false)
        if snaps.empty?
          puts 'ERROR: no snapshots available'
          exit(2)
        else
          snap = snaps['snapshots'][-1]['snapshot']
          if not o[:index].nil?
            data = { 'indices' => o[:index] }
          else
            data = {}
          end
          es_post(o[:host],"_snapshot/#{o[:repo]}/#{snap}/_restore?wait_for_completion=true",data,o[:port],o[:verbose])
        end
      else
        puts "restore snap with name #{o[:restore]} from repository #{o[:repo]}"
        if not o[:index].nil?
          data = { 'indices' => o[:index] }
        else
          data = {}
        end
        es_post(o[:host],"_snapshot/#{o[:repo]}/#{o[:restore]}/_restore?wait_for_completion=true",data,o[:port],o[:verbose])
      end
    else
      puts 'ERROR: cannot restore, need repo'
      exit(2)
    end

  elsif o[:list] == true
    if not o[:repo].nil?
      puts "listing all snap from repository #{o[:repo]}"
      es_get(o[:host],"_snapshot/#{o[:repo]}/_all",o[:port],true)
    else
      puts 'listing all repository information'
      es_get(o[:host],'_snapshot/_all',o[:port],true)
    end

  elsif not o[:repo].nil?
    if o[:delete]
      puts "Deleting repository #{o[:repo]}"
      es_delete(o[:host],"_snapshot/#{o[:repo]}",o[:port],o[:verbose])
    else
      if o[:repolocation].nil?
        puts "ERROR: need repository location for repository creation"
        exit(2)
      else
        puts "Creating repository #{o[:repo]} on location #{o[:repolocation]}"
        data = {'type' => 'fs', 'settings' => { 'location' => o[:repolocation] , 'compress' => 'false'}}
        es_put(o[:host],"_snapshot/#{o[:repo]}",data,o[:port],o[:verbose])
      end
    end

  else
    puts "run #{$0} --help"
  end
end


def es_get(host,url,port=9200,print=false)
    uri = URI("http://#{host}:#{port}/#{url}")
    http = Net::HTTP.new(uri.host, uri.port)
    req = Net::HTTP::Get.new(uri.path)
    #req['content-type'] = 'application/json'
    #req['accept'] = 'application/json'
    res = http.request(req)
    data = JSON.parse(res.body)
    pp data if print
    data
end

def es_post(host,url,data,port=9200,print=false)
    uri = URI("http://#{host}:#{port}/#{url}")
    http = Net::HTTP.new(uri.host, uri.port)
    req = Net::HTTP::Post.new(uri.path)
    req.body = data.to_json
    req['content-type'] = 'application/json'
    req['accept'] = 'application/json'
    res = http.request(req)
    pp JSON.parse(res.body) if print
end

def es_put(host,url,data,port=9200,print=false)
    uri = URI("http://#{host}:#{port}/#{url}")
    http = Net::HTTP.new(uri.host, uri.port)
    req = Net::HTTP::Put.new(uri.path)
    req.body = data.to_json
    req['content-type'] = 'application/json'
    req['accept'] = 'application/json'
    res = http.request(req)
    pp JSON.parse(res.body) if print
end

def es_delete(host,url,port=9200,print=false)
    uri = URI("http://#{host}:#{port}/#{url}")
    http = Net::HTTP.new(uri.host, uri.port)
    req = Net::HTTP::Delete.new(uri.path)
    #req['content-type'] = 'application/json'
    #req['accept'] = 'application/json'
    res = http.request(req)
    data = JSON.parse(res.body)
    pp data if print
end

roller(options)
