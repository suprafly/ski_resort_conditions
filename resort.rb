#!/usr/bin/env ruby

require 'rubygems'
require 'dm-core'

class Resort
  include DataMapper::Resource
	property :id, Serial
	property :name, String
	property :state, String
	property :link, String
	property :stats, Text
	property :stats_reported_at, String	#Stats Reported last updated
	property :last_updated, DateTime	#Record last updated
end

DataMapper.finalize
