#!/usr/bin/env ruby


require 'net/http'
require 'uri'



class Spider
  def initialize(u)
    @z = Hash.new
    @links = Hash.new
    @url = URI.parse(u)
    if (@url.path).empty?
	@url.path = "/"
    end

  end

  def crawl_page(path)	
   begin
    res = Net::HTTP.get_response(path)             
    rescue Exception
      puts "\nThere was an Error: #{$!}"
    end

    if (res.code == '200')
	return res.body 
    else
        return "Code: #{res.code}\nMessage: #{res.message}"
    end

   end

  def link_parser(page)		#PARSE OUT LOCAL LINKS
    c = Array.new
    find_usa = page.scan(/<h4>\s*usa\s*ski\s*reports\s*<\/h4>([\w\W\s\S\d\D]*)<h4>\s*Canada/i) { |temp|
	c = temp[0].split("\n") 
	
    }

    c.each do |x| 
	if x != ""
	   t = x.split(/<p>\s*<a\s*href\s*=\s*"\s*([\w\W\s\S\d\D]*)\s*"\s*title\s*=\s*"\s*([\w\W\s\S\d\D]*)\s*"\s*class="irss">([\w\W\s\S\d\D]*)<\/a><\/p>/i)
	   y = t[1].split(/\/([\w]*)\/snow.rss/i)

	   @z[y[1]] = t[1] 	#build a hash containing each state and its rss local path

	end

    end



  end

  def crawl_begin()	
	z = Hash.new
    	p = crawl_page(@url)
	link_parser(p)		

	@z

  end

end

weburl = ARGV[0]
crawler = Spider.new(weburl)

crawler.crawl_begin() 


