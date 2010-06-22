
class NilClass
  def maybe(*a, &b) self end
end

module Boolean
  def checked; self ? 'checked="checked"' : '' end
end

class TrueClass
  include Boolean
end

class FalseClass
  include Boolean
end

class Object
  alias :maybe :send
end

module Enumerable
  def invoke(m, *args)
    return self.map { |i| i.send(m, *args) } unless block_given?
    self.each { |i| yield i.send(m, *args) }
  end

  def pluck(*args)
    return self.map { |i| i.send(:[], *args) } unless block_given?
    self.each { |i| yield i.send(:[], *args) }
  end

  def to_data_attrs
    self.map { |k, v| "data-#{k}=\"#{v}\"" }.join(' ')
  end
end

class Array
  def invoke!(m, *args)
    return self.map! { |i| i.send(m, *args) } unless block_given?
    self.map! { |i| yield i.send(m, *args) }
  end

  def pluck!(*args)
    return self.map! { |i| i.send(:[], *args) } unless block_given?
    self.map! { |i| yield i.send(:[], *args) }
  end
end


require 'digest'


class String
  def md5; Digest::MD5.hexdigest(self) end
end


