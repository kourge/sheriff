# vim:set filetype=ruby:

require 'rubygems'

load 'compatibility.rb' if RUBY_VERSION < '1.8.7'

require 'sinatra/base'
require 'app'

class SheriffApp < Sinatra::Base
  disable :show_exceptions
  set :environment => :production
end

run SheriffApp
