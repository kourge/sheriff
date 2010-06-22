require 'icalendar'

helpers do
  def blank_calendar
    cal = Icalendar::Calendar.new
    {
      'X-WR-CALNAME' => 'Mozilla Sheriff Schedule',
      'X-WR-TIMEZONE' => 'America/San_Jose'
    }.each { |k, v| cal.custom_property k, v }

    cal.timezone do
      timezone_id 'America/San_Jose'

      standard do
        timezone_name 'PST'
        timezone_offset_from '-0700'
        timezone_offset_to '-0800'
        dtstart '19701101T020000'
        add_recurrence_rule 'YEARLY;BYMONTH=11;BYDAY=1SU'
      end

      daylight do
        timezone_name 'PDT'
        timezone_offset_from '-0800'
        timezone_offset_to '-0700'
        dtstart '19700308TO20000'
        add_recurrence_rule 'FREQ=YEARLY;BYMONTH=3;BYDAY=2SU'
      end
    end

    cal
  end
end

get %r{/ical/(all|duty).ics} do |scope|
  mail = request['sheriff_mail']
  error 400, "A sheriff was not specified" if scope == 'duty' and mail.nil?

  cal = blank_calendar
  (mail ? Day.where(:sheriff_mail => mail) : Day).each do |day|
    cal.event do
      dtstart day.day
      dtend day.day.succ
      summary "#{day.sheriff.fullname} (#{day.sheriff.nick})"
      uid "#{day.day}@sheriff.mozilla.org"
      dtstamp DateTime.parse(day.updated.strftime('%FT%T%z'))
      seq day.revisions
      status 'CONFIRMED'
      transp
    end
  end

  content_type 'text/calendar', :charset => 'utf-8'
  cal.publish
  cal.to_ical
end

get '/ical/requests.ics' do
  cal = blank_calendar
  Subbing.actives.where(:request => true).each do |req|
    cal.event do
      dtstart req.day.day
      dtend req.day.day.succ
      summary "#{req.subject.fullname} (#{req.subject.nick})"
      description req.comment
      uid "#{req.id}@sheriff.mozilla.org"
      dtstamp DateTime.parse(Time.now.strftime('%FT%T%z'))
      status 'CONFIRMED'
      transp
    end
  end

  content_type 'text/calendar', :charset => 'utf-8'
  cal.publish
  cal.to_ical
end

