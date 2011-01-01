
require 'sinatra'
require 'builder'


post '/' do
 builder do |xml|
	xml.instruct!
	xml.Response do
		xml.Say("Hello cock")
	
 end


end
