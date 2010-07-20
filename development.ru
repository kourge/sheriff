# vi:set filetype=ruby:

require 'rubygems'

load 'compatibility.rb' if RUBY_VERSION.split('.').map { |s| s.to_i }[2] < 7

require 'sinatra'

disable :run
enable :show_exceptions
set :environment => :development

require 'app'
run Sinatra::Application
