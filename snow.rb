#!/usr/bin/env ruby

require 'resort.rb'
require 'spider.rb'

require 'time'
require 'open-uri'
require 'simple-rss'
require 'rubygems'
require 'dm-core'
require 'dm-migrations'
require 'dm-validations'

class Snow
  def initialize()
	DataMapper::Logger.new($stdout, :debug)
	DataMapper.setup(:default, 'sqlite:///home/truck/programs/snow/snow_report.db')
	DataMapper.auto_upgrade!
	#Setup database
	@resorts = Array.new
	@usa_states = Array.new
	@out_mess = "\nFor a list of resorts by state type 'ls' followed by the state or abbreviation (ex: CA).\nFor the current conditions of any resort, type 'stats' followed by the resort name.\nTo quit type 'quit'"
	@state_switch = { "ak" => "alaska", "az" => "arizona", "ca" => "california", "co" => "colorado", "ct" => "connecticut", "id" => "idaho", "il" => "illinois", "in" => "indiana", "ia" => "iowa", "me" => "maine", "md" => "maryland", "ma" => "massachusetts", "mi" => "michigan", "mn" => "minnesota", "mo" => "missouri", "mt" => "montana", "nv" => "nevada", "nh" => "new-hampshire", "nj" => "new-jersey", "nm" => "new-mexico", "ny" => "new-york", "nc" => "north-carolina", "oh" => "ohio", "or" => "oregon", "pa" => "pennsylvania", "sd" => "south-dakota", "tn" => "tennessee", "ut" => "utah", "vt" => "vermont", "va" => "virginia", "wa" => "washington", "wi" => "wisconsin", "wy" => "wyoming" }
	@state_other = @state_switch.invert
	@usa = Spider.new("http://www.onthesnow.com/site_map_rss.html")
	@usa_states = @usa.crawl_begin
  end

  def get_rss()
	@usa_states.each do |key, value|
		key = key.chomp
		source = "http://www.onthesnow.com#{value}"
		path = value
		if (key == "CN") || (key == "CS")
			key = "CA"
			path = "california"
		end
		content = ""
		open(source) do |n| content = n.read end
		rss = SimpleRSS.parse(content)

		rss.items.each do |x|

		    full_path = x.guid.gsub(/skireport.html([\w\W\s\S\d\D]*)/,"snow.rss")

		    nm = x.title.downcase.gsub(/&#x27;/,"'")
		    nm = nm.gsub(".","")
		    nm = nm.gsub(/mountain/,"mtn")
		    nm = nm.gsub(/mt/,"mount")
		    nm = nm.gsub(/resort/,"")
		    nm = nm.gsub(/ski\s*/,"")
		    nm = nm.gsub(/area/,"")

		    if nm != "blandford" && Resort.first(:name => x.title.downcase) == nil
	              @resorts = Resort.create(
			:name	=> nm,
			:state	=> key.downcase,
			:link	=> full_path,
			:stats_reported_at => x.date,
			:last_updated	=> Time.now,
			:stats	=> x.description
		      )
		      @resorts.save

		    end
		end
	end

  end

  def update_rss(net)
	n = Time.new
	content = ""
	open(net.link) do |n| content = n.read end
	rss = SimpleRSS.parse(content)
	if (Time.now.hour > net.last_updated.hour)
		net.update(:last_updated => Time.now, :stats => rss.items[0].description, :stats_reported_at => rss.items[0].date)
		net.save
	end
  end
  
  def wipe
	DataMapper.auto_migrate!
	get_rss
  end

  def print_resort(net)
	puts "\n#{net.name.upcase}, #{net.state.upcase}\nLast updated: #{net.last_updated.strftime("%m/%d/%Y @ %I:%M%p")}"
	puts "\n#{net.stats.gsub("/ ","\n")}"
  end

  def interact
    comm = []
    while (comm[0] != "quit")
    puts @out_mess
    mode = ((STDIN.gets).chomp).downcase
    mode = mode.gsub(".","")
    mode = mode.gsub("mountain","mtn")
    mode = mode.gsub("mt","mount")
    mode = mode.gsub("resort","")
    mode = mode.gsub("ski","")
    mode = mode.gsub("area","")

    comm = mode.split(" ")

    if comm[1] != nil
     if comm[0] == "ls"
	u = mode.gsub!("ls\s","").gsub(" ","-")
	  if comm[1].length == 2
		net = Resort.all(:state => comm[1])
	  else
		net = Resort.all(:state => @state_other[u])
	  end
   	  net.each do |a|
	     puts "#{a.name}"
	  end
	  puts "Cannot find the state #{u.upcase}. Please check your spelling and try again."
     elsif comm[0] == "stats"
	u = mode.gsub!("stats\s","")
	net = Resort.first(:name => u)
	if net != nil
	  update_rss(net)
	  print_resort(net)	
	else
	  c = 0
	  net2 = Resort.all
	  net2.each do |y|
		if y.name.include?(u)
			update_rss(y)
		  	print_resort(y)
			c += 1
		end
	  end
	  if c == 0
		puts "Cannot find any resort called #{u.upcase}. Please check your spelling and try again."
	  end
	end

     elsif comm[0] != "quit"
	puts "Invalid command: #{comm[0]}"
     end
    elsif comm[0] != "quit"
     puts "Not enough parameters."
    end
   end
  end
end	#END CLASS

snow_rep = Snow.new
puts "\n1 to update database, 2 to wipe/load database: "
mode = (STDIN.gets).to_i
snow_rep.get_rss() if mode == 1
snow_rep.wipe() if mode == 2
snow_rep.interact


