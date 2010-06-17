# vi:set filetype=ruby

require 'rubygems'
require 'sinatra'

disable :run
set :environment => :production

require 'app'
run Sinatra::Application
