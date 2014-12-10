require "rubygems"
require "sinatra"

require File.expand_path '../sms_hub.rb', __FILE__

run SmsHub
