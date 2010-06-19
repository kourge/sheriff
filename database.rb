
require 'sequel'

$db = lambda { Sequel.send(SETTINGS['db']['driver'], SETTINGS['db']) }
$db.call

# DB is a bare-bone delegate (proxy object) to a new Sequel::Database instance
# on every method call. This way, no MySQL connections would be left open and
# hanging until the server shuts it down 8 hours later.
# tl;dr This prevents the "MySQL server has gone away" exception.
DB = Object.new
class << DB
  def method_missing(*a, &b) $db.call.send(*a, &b) end
end

class Sheriff < Sequel::Model
  one_to_many :days, :key => :sheriff_mail
end

class Day < Sequel::Model
  many_to_one :sheriff, :key => :sheriff_mail
  one_to_many :subbings, :key => :day_day
end

class MockDay < Struct.new(:day, :sheriff)
  def self.where(clauses)
    return [] if not clauses[:day]
    result, sheriffs = [], Sheriff.all
    pool = sheriffs.sort { rand }
    clauses[:day].each do |day|
      pool = sheriffs.sort { rand } if pool.empty?
      result << self.new(day, pool.pop)
    end
    result
  end
end

class Subbing < Sequel::Model
  many_to_one :subject, :key => :subject_mail, :class => :Sheriff
  many_to_one :object, :key => :object_mail, :class => :Sheriff
  many_to_one :day, :key => :day_day

  HASH_FACTORS = [:subject_mail, :request_mail, :day]

  def self.calculate_id(o) HASH_FACTORS.map { |v| o[v].to_s }.join('').md5 end
  def calculate_id; self.id = self.class.calculate_id(self) end

  def self.fetch(hash) self[hash[:id] || self.calculate_id(hash)] end

  def self.of(o)
    mail = o.respond_to?(:attribute_names) ? o.mail[0] : o
    self.where({:subject_mail => mail} | {:object_mail => mail})
  end

  # Whatever responds to attribute_names is presumed to be an LDAP user
  def directed_to?(o)
    self.object_mail == (o.respond_to?(:attribute_names) ? o.mail[0] : o)
  end

  def issued_by?(user)
    self.subject_mail == (o.respond_to?(:attribute_names) ? o.mail[0] : o)
  end

  plugin :validation_helpers
  def validate
    super
    email = /\A([^@\s]+)@((?:[-a-z0-9]+.)+[a-z]{2,})\Z/i
    email_error = 'should be a valid sheriff email address'
    validates_presence :subject_mail
    validates_format email, :subject_mail, :message => email_error

    if not self.request
      validates_presence :object_mail
      validates_format email, :object_mail, :message => email_error
    end
  end
end

