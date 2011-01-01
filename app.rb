
require 'sinatra'
require 'builder'


post '/' do
 builder do |xml|
	xml.instruct!
	xml.Response do
		xml.Say("Hello, Rebecca. The man across from you has a crush on you.")
	end
 end


end
