
class Regexp
  class << self
    alias :_union :union
    def union(*a)
      a = a[0] if a[0].kind_of? Array
      self._union *a
    end
  end
end

module Fix; end unless defined? Fix

module Fix::IOFix
  def getbyte; self.getc; end
end

class IO
  include Fix::IOFix
end

class StringIO
  include Fix::IOFix
end

