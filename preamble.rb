# coding: utf-8

SETTINGS = YAML.load_file('config.yaml')

mime :plain, 'text/plain'
mime :json, 'application/json'

helpers do
  def accept_html?; request.accept.first == 'text/html' end
  def accept_json?; request.accept.first == 'application/json' end

  def redirect_back
    referer = request.referer
    if referer =~ /login|logout/ then redirect '/' else redirect referer end
  end

  def error(status_code, string)
    if accept_json?
      content_type :json
      halt status_code, {:error => string}.to_json
    else
      halt status_code, erb(:error, :locals => {:message => string})
    end
  end

  include Rack::Utils
end

use Rack::Session::Cookie, :key => 'rack.session', :secret => SETTINGS['secret']

require 'rack-flash'
use Rack::Flash, :accessorize => [:notice, :error]

