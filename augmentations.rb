
class NilClass
  def maybe(*a) self end
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

