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
      @holidays = holidays
    end

    def working_hours_between from, to
      from, to, sign = invert_if_needed from, to
      (from.to_date..to.to_date).map do |date|
        filters = {}
        filters[:from] = from if date == from.to_date
        filters[:to] = to if date == to.to_date
        business_day(date).working_hours filters
      end.sum.round(2) * sign
    end

    def add_business_days date, days
      date + days
    end

    private

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
      @working_hours[date.strftime('%a')]
    end
  end
end
