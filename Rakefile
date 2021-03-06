
require 'date'
require 'yaml'
BASEDIR = File.dirname(__FILE__)
$: << BASEDIR
SETTINGS_FILE = File.join(BASEDIR, 'config.yaml')
SETTINGS = YAML.load_file(File.expand_path(SETTINGS_FILE))


task :default => [:next_week_assignment, :upcoming_notification]


task :next_week_assignment do
  wednesday, friday = 3, 5
  if Date.today.wday == wednesday or ENV['immediately'] == 'true'
    require 'rubygems'

    load 'augmentations.rb'
    load 'database.rb' unless defined?(DB)

    last_day = case ENV['last_day']
      when nil then Day.order(:day).last.day
      when 'today' then Date.today
      else Date.parse(ENV['last_day'])
    end
    # Assuming that the last day is always a Friday.
    date = last_day + 3
    weeks_to_fill = (ENV['weeks_ahead'] || 1).to_i

    next_ups = weeks_to_fill * 5
    fill_up = lambda do |sheriff|
      Day.new(:sheriff_mail => sheriff.mail) { |d| d.day = date }.save
      date += (date.wday == friday) ? 3 : 1
    end

    # Consider the tenderfeet (those who've just become sheriffs) first.
    tenderfeet = Sheriff.left_join(
      :days, :sheriff_mail => :mail
    ).where(:sheriff_mail => nil, :serving => true)
    next_ups -= tenderfeet.count
    tenderfeet.each(&fill_up)

    # A sheriff with a higher index will be more favored, where the index is
    # the number of days since the sheriff last served duty.
    Sheriff.join(:days, :sheriff_mail => :mail).group_by(:mail).select_append {
      MAX(day).as(index)
    }.order_by(:index).where(:serving).limit(next_ups).each(&fill_up)
  end
end


task :upcoming_notification do
  if Time.now.hour == 0
    require 'rubygems'
    require 'erb'
    require 'ostruct'
    require 'pony'

    load 'augmentations.rb'
    load 'database.rb' unless defined?(DB)

    Sheriff.where(
      :upcoming_duty_notifications => true
    ).order(:days_in_advance_for_upcoming_duty).each do |sheriff|
      days_in_advance = sheriff.days_in_advance_for_upcoming_duty
      fast_forward = Day[Date.today + days_in_advance]

      next if fast_forward.nil? or fast_forward.sheriff != sheriff

      time_range = case days_in_advance
        when 0 then 'today'
        when 1 then 'tomorrow'
        else "in #{days_in_advance} days"
      end

      template = nil
      template_filename = File.join(BASEDIR, 'mail', 'upcoming_duty.erb')
      open(template_filename, 'r') { |f| template = f.read }
      Pony.mail(
        :from => SETTINGS['mail']['from'], :to => sheriff.mail,
        :subject => "You're up for sheriffing #{time_range}",
        :body => ERB.new(template).result(OpenStruct.new(
          :sheriff => sheriff, :time_range => time_range
        ).send(:binding))
      )
    end
  end
end


task :rehash_subbings do
  require 'rubygems'

  load 'augmentations.rb'
  load 'database.rb' unless defined?(DB)

  Subbing.each do |sub|
    old_id, new_id = sub.id, sub.calculate_id
    Subbing.where(:id => old_id).update(:id => new_id)
  end
end


task :db_setup do
  require 'rubygems'
  require 'yaml'

  load 'augmentations.rb'
  load 'database.rb' unless defined?(DB)

  if DB.class.adapter_scheme == :mysql
    Sequel::MySQL.default_charset = 'utf8'
    Sequel::MySQL.default_collate = 'utf8_general_ci'
  end

  DB.create_table :days do
    Date :day, :null => false, :primary_key => true
    String :sheriff_mail, :size => 128
    timestamp :updated, :null => false,
                        :default => Time.parse('1970-01-01 00:00:01')
    Fixnum :revisions, :size => 4, :null => false, :default => 0

    index :sheriff_mail
  end

  DB.create_table :sheriffs do
    String :mail, :size => 128, :null => false, :primary_key => true
    String :nick, :size => 128, :null => false
    String :fullname, :size => 128, :null => false
    TrueClass :serving, :null => false, :default => true

    TrueClass :email_notifications, :null => false, :default => true
    TrueClass :upcoming_duty_notifications, :null => false, :default => true
    Fixnum :days_in_advance_for_upcoming_duty, :null => false, :size => 5,
                                               :default => 2, :unsigned => true
  end

  DB.create_table :subbings do
    String :id, :size => 32, :null => false, :primary_key => true
    String :subject_mail, :size => 128, :null => false
    String :object_mail, :size => 128, :default => nil
    TrueClass :request, :null => false
    FalseClass :fulfilled, :null => false, :default => false
    Date :day_day, :null => false
    longtext :comment, :null => false

    index :subject_mail
    index :day_day
  end

  DB.create_table :sessions do
    String :sid, :size => 32, :null => false, :primary_key => true
    longtext :session
    timestamp :timestamp, :null => false,
                          :default => Time.parse('1970-01-01 00:00:01')

    index :timestamp
  end
end


task :populate_fullnames do
  require 'rubygems'
  require 'yaml'
  require 'net/ldap'

  load 'augmentations.rb'
  load 'database.rb' unless defined?(DB)

  ldap = Net::LDAP.new(
    :host => SETTINGS['ldap']['host'], :port => SETTINGS['ldap']['port']
  )
  ldap.auth(SETTINGS['ldap']['bind_dn'], SETTINGS['ldap']['bind_password'])
  if not ldap.bind
    raise 'LDAP bind failed'
  end
  Sheriff.where(:fullname => '').each do |sheriff|
    filter = Net::LDAP::Filter.eq('mail', sheriff.mail)
    entry = ldap.search(:base => "dc=mozilla", :filter => filter)[0]
    sheriff.update(:fullname => entry.cn[0])
  end
end


task :import_from_google_calendar do
  feed = ENV['feed'] || 'http://www.google.com/calendar/ical/j6tkvqkuf9elual8l2tbuk2umk%40group.calendar.google.com/public/basic.ics'
  raise 'The feed URL must be specified with the "feed" option!' if feed.nil?

  require 'rubygems'
  require 'yaml'
  require 'net/ldap'
  require 'net/http'
  require 'icalendar'
  require 'uri'
  require 'time'

  load 'augmentations.rb'
  load 'database.rb' unless defined?(DB)
  load 'compatibility.rb' if RUBY_VERSION < '1.8.7'

  ldap = Net::LDAP.new(
    :host => SETTINGS['ldap']['host'], :port => SETTINGS['ldap']['port']
  )
  ldap.auth(SETTINGS['ldap']['bind_dn'], SETTINGS['ldap']['bind_password'])
  if not ldap.bind
    raise 'LDAP bind failed'
  end

  new_sheriffs = []
  uri = URI.parse(feed)
  cal = Icalendar.parse(Net::HTTP.get(uri)).first
  cal.events.each do |event|
    next if event.summary == '#developers'
    summary = event.summary.sub(/\(.+\) & .+/, '').strip
    if not summary.include?("(")
      name = summary
      nick = ''
    else
      name = summary.match(/^(.+?) \(/)[1]
      nick = summary.match(/\(([^)(]+)\)$/)[1]
    end

    search = lambda do |attrib, value|
      filter = Net::LDAP::Filter.eq(attrib, value)
      r = ldap.search(:base => 'dc=mozilla', :filter => filter)
      r.each do |entry|
        entry.instance_variable_get(:@myhash).delete(:jpegphoto)
      end
      r
    end

    entries = search.call('cn', name)
    entries = search.call('cn', "*#{nick}*") if entries.empty?
    entries = search.call('im', "*#{nick}*") if entries.empty?

    if entries.empty?
      STDERR.puts "Could not find \"#{summary}\" in LDAP"
      next
    end
    next if entries.length > 1
    entry = entries.first
    mail = entry.mail[0]

    if not Sheriff[mail]
      sheriff = Sheriff.new(
        :nick => nick, :fullname => name
      ) { |s| s.mail = mail }.save
      puts "Added sheriff: #{sheriff.inspect}" if ENV['verbose'] == 'true'
    end

    if not Day[event.dtstart]
      day = Day.new(
        :sheriff_mail => mail, :updated => Time.parse(event.dtstamp.strftime)
      ) { |d| d.day = event.dtstart }.save
      puts "Added day: #{day.inspect}" if ENV['verbose'] == 'true'
    end
  end
end


task :compile_markdown do
  require 'rubygems'
  begin
    require 'rdiscount'
    BlueCloth = RDiscount
  rescue LoadError
    require 'bluecloth'
  end

  input, output = ENV['input'], ENV['output']
  raise 'Input and output need to be specified' if not input or not output
  open(input, 'r') do |ins|
    open(output, 'w') do |out|
      r = BlueCloth.new(ins.read)
      out.write(r.to_html)
    end
  end
end


