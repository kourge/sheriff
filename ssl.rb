
require 'rack-ssl-enforcer'

class SheriffApp < Sinatra::Base
  use Rack::SslEnforcer
end

