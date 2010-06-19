
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
    weeks_to_fill = 1

    # A sheriff with a higher index will be more favored, where the index is
    # the number of days since the sheriff last served duty.
    Sheriff.join(
      :days, :sheriff_mail => :mail
    ).group_by(:mail).order_by(:last_day).select_append {
      MAX(day).as(last_day)
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

    load 'augmentations.rb'
    load 'database.rb'

    SETTINGS = YAML.load_file('config.yaml')

    Sheriff.where(
      :upcoming_duty_notification => true
    ).order(:days_in_advance_for_upcoming_duty).each do |sheriff|
      days_in_advance = sheriff.days_in_advance_for_upcoming_duty
      fast_forward = Date.today + days_in_advance

      next unless Day[fast_forware].sheriff == sheriff

      time_range = case days_in_advance
        case 0 then 'today'
        case 1 then 'tomorrow'
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

