# vi:set filetype=ruby

require 'rubygems'
require 'sinatra'

disable :run
enable :show_exceptions
set :environment => :development

require 'app'
run Sinatra::Application
