# vi:set filetype=ruby:

require 'rubygems'

if RUBY_VERSION.split('.').map { |s| s.to_i }[2] < 7
  class Regexp
    class << self
      alias :_union :union
      def union(*a)
        a = a[0] if a[0].kind_of? Array
        self._union *a
      end
    end
  end
end

require 'sinatra'

disable :run
set :environment => :production

require 'app'
run Sinatra::Application
