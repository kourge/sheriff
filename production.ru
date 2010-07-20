# vi:set filetype=ruby:

require 'rubygems'

load 'compatibility.rb' if RUBY_VERSION.split('.').map { |s| s.to_i }[2] < 7

require 'sinatra'

disable :run
set :environment => :production

require 'app'
run Sinatra::Application
