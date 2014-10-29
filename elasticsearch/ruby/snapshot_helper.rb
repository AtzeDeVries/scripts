#!/usr/bin/ruby

require 'net/http'
require 'uri'
require 'json'
require 'pp'

ARGV.each do |a|
  puts "Argument: #{a}"
end

$host = 'localhost'
$port = '2005'

def guide_tasks
  case ARGV[0]
  when 'search'
    es_get(host,'_search',port,true)

  when 'snapshot'
    case ARGV[1]
    when 'list'
      if ARGV[2].nil?
        puts 'Need a snapshot repository'
      else
        es_get($host,"_snapshot/#{ARGV[2]}/_all",$port,true)
      end
    when 'repo'
      case ARGV[2]
      when 'create'
        if ARGV[4].nil?
          puts 'need atleast 3 arugments. a repository name and a location '
        else
          puts "creating repo #{ARGV[3]} on location #{ARGV[4]}"
          data = { 'type' => 'fs', 'settings' => { 'location' => "#{ARGV[4]}", 'compress' => 'false'} }
          es_post($host,"_snapshot/#{ARGV[3]}",data,$port,true)
        end
      when 'delete'
        if ARGV[3].nil?
          puts 'need atleast 2 arugments. a repository name'
        else
          puts "deleting repo #{ARGV[3]}"
          #data = { 'type' => 'fs', 'settings' => { 'location' => "#{ARGV[4]}", 'compress' => 'false'} }
          es_delete($host,"_snapshot/#{ARGV[3]}",$port,true)
        end
      else
        if ARGV[2].nil?
          puts 'no argument given. need a repo name'
        else
          puts "#{ARGV[0]} is not known"
        end
      end

    else
      if ARGV[1].nil?
        puts 'Current snapshot repositories in elasticsearch localhost'
        es_get($host,'_snapshot',$port,true)
      else
        puts "#{ARGV[1]} is an unknown argument to snapshot"
      end
    end

  else
    if ARGV[0].nil?
      puts 'no argument given nothing to do'
    else
      puts "#{ARGV[0]} is not known known repo"
    end
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
end

def es_post(host,url,data,port=9200,print=false)
    uri = URI("http://#{host}:#{port}/#{url}")
    http = Net::HTTP.new(uri.host, uri.port)
    req = Net::HTTP::Post.new(uri.path)
    #auth_data = { 'auth' => { 'tenantName' => resource[:tenant], 'passwordCredentials' => { 'username' => resource[:username], 'password' => resource[:password] } } }
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

guide_tasks
