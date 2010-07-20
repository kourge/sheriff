# coding: utf-8

SETTINGS = YAML.load_file('config.yaml')

mime_type :plain, 'text/plain'
mime_type :json, 'application/json'

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

load 'mail.rb' if SETTINGS['mail']['enabled']
load 'feeds.rb' if SETTINGS['ical']['enabled']

