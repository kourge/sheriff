# vim:set filetype=ruby:

require 'rubygems'

load 'compatibility.rb' if RUBY_VERSION < '1.8.7'

require 'sinatra/base'
require 'app'

class SheriffApp < Sinatra::Base
  enable :show_exceptions
  set :environment => :development
end

run SheriffApp
