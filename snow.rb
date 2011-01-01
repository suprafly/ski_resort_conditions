#!/usr/bin/env ruby

require 'db.rb'
require 'spider.rb'
require 'sinatra'
require 'builder'

require 'rss/1.0'
require 'rss/2.0'
require 'rubygems'
require 'dm-core'
require 'dm-migrations'
require 'dm-validations'


class Snow

  def initialize()


  end


end

	DataMapper::Logger.new($stdout, :debug)

	DataMapper.setup(:default, 'sqlite:///home/truck/programs/snow/snow_report.db')
	DataMapper.auto_upgrade!

	#Setup database
	@resorts = Array.new
	@usa_states = Array.new

	@state_switch = { "ak" => "alaska", "az" => "arizona", "ca" => "california", "co" => "colorado", "ct" => "connecticut", "id" => "idaho", "il" => "illinois", "in" => "indiana", "ia" => "iowa", "me" => "maine", "md" => "maryland", "ma" => "massachusetts", "mi" => "michigan", "mn" => "minnesota", "mo" => "missouri", "mt" => "montana", "nv" => "nevada", "nh" => "new-hampshire", "nj" => "new-jersey", "nm" => "new-mexico", "ny" => "new-york", "nc" => "north-carolina", "oh" => "ohio", "or" => "oregon", "pa" => "pennsylvania", "sd" => "south-dakota", "tn" => "tennessee", "ut" => "utah", "vt" => "vermont", "va" => "virginia", "wa" => "washington", "wi" => "wisconsin", "wy" => "wyoming" }

	@state_other = @state_switch.invert

	@usa = Spider.new("http://www.onthesnow.com/site_map_rss.html")
	@usa_states = @usa.crawl_begin


#Now, we have a hash containing all states with a link to the RSS feed for all of the resorts in all of the states

#We need to loop through the hash and drop each resort into the database, assigning the correct state to each
puts "\n1 to reload database: "
mode = (STDIN.gets).to_i

if mode == 1

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
		rss = RSS::Parser.parse(content, false)

		0.upto(rss.items.size-1) { |x|
		    full_path = ["http://www.onthesnow.com/#{@state_switch[key.downcase]}/",((rss.items[x].title).gsub(" ","-")).downcase,"/snow.rss"].join
		    
		    nm = rss.items[x].title.downcase

		    if Resort.first(:name => rss.items[x].title.downcase) == nil
	              @resorts = Resort.create(
			:name	=> rss.items[x].title.downcase,
			:state	=> key.downcase,
			:link	=> full_path,
			:stats_reported_at => rss.items[x].date,
			:last_updated	=> Time.now,
			:stats	=> rss.items[x].description
		      )

		      @resorts.save
		    end

		}

	end

end

	
comm = []
while (comm[0] != "quit")

  puts "\nFor a list of resorts by state type 'ls' followed by the state or abbreviation (ex: CA).\nFor the current conditions of any resort, type 'stats' followed by the resort name.\nTo quit type 'quit'"
  mode = ((STDIN.gets).chomp).downcase
  comm = mode.split(" ")


  if comm[0] == "ls"
	u = mode.gsub!("ls\s","").gsub(" ","-")

	if comm[1].length == 2
		net = Resort.all(:state => comm[1])
#Error test here
	else
		net = Resort.all(:state => @state_other[u])
#Error test here
	end

	net.each do |a|
		puts "#{a.name}"
	end

  elsif comm[0] == "stats"
	u = mode.gsub!("stats\s","")
	net = Resort.first(:name => u)
	puts "\n#{net.name.upcase}\n#{net.stats}"
  else
	puts "Invalid command."
  end
  


end
#puts " #{net}\n" if net != nil


#NOW, We need to provide support for spelling.. mt/mt./mount .. ski/ski resort.. at/... mtn/mountain.. resort/.. 

#AND support for non numerical characters, apostrophes

#AND for numbers



