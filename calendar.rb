
require 'date'

class Month
  attr_reader :month, :year

  def initialize(*args)
    case args.map { |o| o.class }
      when [Fixnum, Fixnum]
        @month, @year = *args
      when [Date]
        @month, @year = args[0].month, args[0].year
    end
  end

  def weeks
    days_of_first_week = 7 - Date.new(@year, @month, 1).wday
    first_week = (1..days_of_first_week).to_a
    first_week.unshift nil while first_week.size != 7
    first_day_of_second_week = Date.new(@year, @month, days_of_first_week + 1)
    last_day_of_month = Date.new(@year, @month, -1)
    remaining_days = (first_day_of_second_week..last_day_of_month).map do |d|
      d.day
    end
    remaining_weeks = []
    remaining_weeks << remaining_days.slice!(0, 7) while !remaining_days.empty?
    remaining_weeks[-1] << nil while remaining_weeks[-1].size != 7
    [first_week] + remaining_weeks
  end

  def weeks_before(day, inclusive=true)
    index = self.nth_week_of(day)
    return [] if not inclusive and index == 0
    index -= 1 if not inclusive
    self.weeks[0..index]
  end

  def weeks_after(day, inclusive=true)
    index = self.nth_week_of(day)
    return [] if not inclusive and index == (self.weeks.size - 1)
    index += 1 if not inclusive
    self.weeks[index..-1]
  end

  def nth_week_of(day) self.weeks.index(self.week_of(day)) end

  def week_of(day)
    day = day.day if day.kind_of? Date
    self.weeks.find { |a| a.include? day }
  end

  include Comparable

  def total_months; @year * 12 + @month - 1; end
  def hash; self.total_months; end
  def <=>(other); self.total_months - other.total_months; end

  def +(i)
    i += self.total_months
    self.class.new((i % 12) + 1, i / 12)
  end

  def -(o)
    return self + (-o) if o.kind_of? Integer
    return self.hash - o.hash if o.kind_of? self.class
    raise ArgumentError.new('Operand is neither an Integer nor a Month')
  end

  def succ; self + 1; end

  def inspect; "#<#{self.class} @month=#{@month}, @year=#{@year}>"; end
  def to_s; "#{@year}-#{@month.to_s.rjust(2, '0')}"; end

  def to_date; Date.new @year, @month, 1; end
end

class Date
  def window(before=1, after=3)
    first = self - (7 * before)
    first -= first.wday
    last = self + (7 * after)
    last += 6 - last.wday
    (first..last)
  end

  def to_month; Month.new self end
end

get '/calendar' do
  from, to = Date.parse(request['from']), Date.parse(request['to'])
end

