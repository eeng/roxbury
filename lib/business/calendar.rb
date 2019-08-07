require 'active_support/time'
require 'business/calendar/version'
require 'business/day'
require 'business/non_working_day'

module Business
  class Calendar
    DAYS_OF_THE_WEEK = %w[Mon Tue Wed Thu Fri Sat Sun]

    attr_reader :working_hours

    def initialize working_hours: {}, holidays: []
      @working_hours = DAYS_OF_THE_WEEK.inject({}) do |wh, dow|
        wh.merge dow => Day.parse(working_hours[dow], dow)
      end
      @holidays = Set.new(holidays)
    end

    def working_hours_between from, to
      from, to = cast_time(from, :start), cast_time(to, :end)
      from, to, sign = invert_if_needed from, to

      working_hours_per_day = (from.to_date..to.to_date).map do |date|
        filters = {}
        filters[:from] = from if date == from.to_date
        filters[:to] = to if date == to.to_date
        business_day(date).working_hours filters
      end

      working_hours_per_day.sum.round(2) * sign
    end

    def working_days_between from, to
      working_hours_between(from, to) / max_working_hours_in_a_day.to_f
    end

    def add_working_hours to, number_of_hours
      to = cast_time(to, :start)

      rolling_timestamp = snap_to_beginning_of_next_business_day(to)
      remaining_hours = number_of_hours

      until (bday = business_day(rolling_timestamp)).include?(rolling_timestamp + remaining_hours.hours)
        remaining_hours -= bday.working_hours(from: rolling_timestamp)
        rolling_timestamp = snap_to_beginning_of_next_business_day(bday.at_end(rolling_timestamp) + 1.minute)
      end

      rolling_timestamp + remaining_hours.hours
    end

    def snap_to_beginning_of_next_business_day date
      bday = business_day(date)
      if bday.include?(date)
        date
      elsif bday.before_start?(date)
        business_day(date).at_beginning(date)
      else
        snap_to_beginning_of_next_business_day date.change(day: date.day + 1, hour: 0, minute: 0)
      end
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
      dow = Day.date_to_dow(date)
      if holiday? date
        Day.non_working_day(dow)
      else
        @working_hours[dow]
      end
    end

    def max_working_hours_in_a_day
      @working_hours.values.map(&:working_hours).max
    end
  end
end
