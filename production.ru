# vi:set filetype=ruby:

require 'rubygems'

load 'compatibility.rb' if RUBY_VERSION < '1.8.7'

require 'sinatra'

disable :run
set :environment => :production

require 'app'
run Sinatra::Application
