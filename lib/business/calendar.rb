require 'active_support/time'
require 'business/calendar/version'
require 'business/day'

module Business
  class Calendar
    DAYS_OF_THE_WEEK = %w[Mon Tue Wed Thu Fri Sat Sun]

    attr_reader :working_hours

    def initialize working_hours: {}, holidays: []
      @working_hours = DAYS_OF_THE_WEEK.inject({}) do |wh, dow|
        wh.merge dow => Day.parse(working_hours[dow])
      end
      @holidays = Set.new(holidays)
    end

    def working_hours_between from, to
      from, to = cast_time(from, :start), cast_time(to, :end)
      from, to, sign = invert_if_needed from, to

      (from.to_date..to.to_date).map do |date|
        filters = {}
        filters[:from] = from if date == from.to_date
        filters[:to] = to if date == to.to_date
        business_day(date).working_hours filters
      end.sum.round(2) * sign
    end

    def working_days_between from, to
      working_hours_between(from, to) / max_working_hours_in_a_day.to_f
    end

    def add_working_hours to, number_of_hours
      to + number_of_hours.hours
    end

    def holiday? date
      @holidays.include?(date)
    end

    private

    def cast_time date_or_time, start_or_end
      case date_or_time
      when Time then
        date_or_time
      when Date then
        start_or_end == :end ? date_or_time.to_time.end_of_day : date_or_time.to_time
      else
        raise ArgumentError, "Type #{date_or_time.class} not supported"
      end
    end

    def invert_if_needed from, to
      if from > to
        from, to = to, from
        sign = -1
      else
        sign = 1
      end
      [from, to, sign]
    end

    def working_hours_in_day date
      business_day(date).working_hours
    end

    def business_day date
      if holiday? date
        Day.non_working_day
      else
        @working_hours[date.strftime('%a')]
      end
    end

    def max_working_hours_in_a_day
      @working_hours.values.map(&:working_hours).max
    end
  end
end
