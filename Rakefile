
require 'date'


task :default => [:next_week_assignment, :upcoming_notification]


task :next_week_assignment do
  wednesday, friday = 3, 5
  if Date.today.wday == wednesday
    require 'rubygems'

    load 'augmentations.rb'
    load 'database.rb'

    # Assuming that the last day is always a Friday.
    day = Days.order(:day).last.day + 3
    weeks_to_fill = (ENV['weeks_ahead'] || 1).to_i

    # A sheriff with a higher index will be more favored, where the index is
    # the number of days since the sheriff last served duty.
    Sheriff.join(
      :days, :sheriff_mail => :mail
    ).group_by(:mail).order_by(:index).select_append {
      MAX(day).as(index)
    }.limit(weeks_to_fill * 5).each do |sheriff|
      Day.insert(:day => day, :sheriff_mail => sheriff.mail)
      day += (day.wday == friday) ? 3 : 1
    end
  end
end


task :upcoming_notification do
  if Time.now.hour == 0
    require 'rubygems'
    require 'erb'
    require 'pony'

    SETTINGS = YAML.load_file('config.yaml')

    load 'augmentations.rb'
    load 'database.rb'

    Sheriff.where(
      :upcoming_duty_notification => true
    ).order(:days_in_advance_for_upcoming_duty).each do |sheriff|
      days_in_advance = sheriff.days_in_advance_for_upcoming_duty
      fast_forward = Date.today + days_in_advance

      next unless Day[fast_forward].sheriff == sheriff

      time_range = case days_in_advance
        when 0 then 'today'
        when 1 then 'tomorrow'
        else "in #{days_in_advance} days"
      end
      Pony.mail(
        :from => SETTINGS['mail']['from'], :to => sheriff.mail,
        :subject => "You're up for sheriffing #{time_range}",
        :body => erb(:'mail/upcoming_duty', :layout => false, :locals => {
          :sheriff => sheriff, :time_range => time_range
        })
      )
    end
  end
end


task :rehash_subbings do
  require 'rubygems'

  load 'augmentations.rb'
  load 'database.rb'

  Subbing.each do |sub|
    old_id, new_id = sub.id, sub.calculate_id
    Subbing.where(:id => old_id).update(:id => new_id)
  end
end


task :db_setup do
  require 'rubygems'
  require 'yaml'

  SETTINGS = YAML.load_file('config.yaml')

  load 'augmentations.rb'
  load 'database.rb'

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
    TrueClass :fulfilled, :null => false, :default => false
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

  SETTINGS = YAML.load_file('config.yaml')

  load 'augmentations.rb'
  load 'database.rb'

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

  SETTINGS = YAML.load_file('config.yaml')

  load 'augmentations.rb'
  load 'database.rb'
  load 'compatibility.rb' if RUBY_VERSION.split('.').map { |s| s.to_i }[2] < 7

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

    entries = nil
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
      sheriff = Sheriff.new(:nick => nick, :fullname => name)
      sheriff.mail = mail
      sheriff.save
      puts "Added sheriff: #{sheriff.inspect}" if ENV['verbose'] == 'true'
    end

    if not Day[event.dtstart]
      day = Day.new(
        :sheriff_mail => mail, :updated => Time.parse(event.dtstamp.strftime)
      )
      day.day = event.dtstart
      day.save
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


