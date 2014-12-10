require "rubygems"
require "sinatra/base"

class MyApp < Sinatra::Base

  get '/test' do
    'Hello, nginx and unicorn!'
  end

end
