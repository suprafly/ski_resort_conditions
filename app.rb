
require 'sinatra'
require 'builder'


post '/' do
 builder do |xml|
	xml.instruct!
	xml.Response do
		xml.Sms("Hello, cock")
	end
 end


end
