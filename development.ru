# vi:set filetype=ruby:

require 'rubygems'

load 'compatibility.rb' if RUBY_VERSION < '1.8.7'

require 'sinatra'

disable :run
enable :show_exceptions
set :environment => :development

require 'app'
run Sinatra::Application
