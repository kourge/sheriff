
require 'rack-flash'
use Rack::Flash, :accessorize => [:notice, :error]

