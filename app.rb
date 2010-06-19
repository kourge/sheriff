require 'rubygems'
require 'sinatra'
require 'erb'
require 'json'
require 'partials'

load 'augmentations.rb'
load 'preamble.rb'
load 'database.rb'
load 'session-database.rb'
load 'flash.rb'
load 'auth.rb'
load 'calendar.rb'
load 'subbings.rb'
load 'preferences.rb'


get '/' do
  login_required!
  if request['from'] and request['to']
    from, to, today = request['from'], request['to'], request['today']
    partial :calendar, :locals => {
      :today => today.nil? ? Date.today : Date.parse(today),
      :first_day => Date.parse(from), :last_day => Date.parse(to)
    }
  else
    # Complain about the parameters later.
    erb :index
  end
end


get '/roster' do
  login_required!
  erb :roster
end


get '/sample' do erb :sample end


################################################################################


get '/t/u' do
  login_required!
  @user.attribute_names.to_json
end


get '/t/mysql' do
  content_type :json
  Day.map { |d| d.inspect }.to_json
end

