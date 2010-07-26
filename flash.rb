
require 'rack-flash'
class SheriffApp < Sinatra::Base
  use Rack::Flash, :accessorize => [:notice, :error]
end

