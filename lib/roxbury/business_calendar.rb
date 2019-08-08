module Roxbury
  class BusinessCalendar
    DAYS_OF_THE_WEEK = %w[Mon Tue Wed Thu Fri Sat Sun]

    attr_reader :working_hours

    def initialize working_hours: {}, holidays: []
      @working_hours = DAYS_OF_THE_WEEK.inject({}) do |wh, dow|
        wh.merge dow => WorkingHours.parse(working_hours[dow])
      end
      if @working_hours.values.all?(&:non_working?)
        raise ArgumentError, 'You must specify at least one working day in working_hours.'
      end
      @holidays = Set.new(holidays)
    end

    # @param from [Date, Time] if it's a date, it's handled as the beginning of the day
    # @param to [Date, Time] if it's a date, it's handled as the end of the day
    # @return [Float] the number of working hours between the given dates
    def working_hours_between from, to
      from, to, sign = invert_if_needed cast_time(from, :start), cast_time(to, :end)

      working_hours_per_day = (from.to_date..to.to_date).map do |date|
        filters = {}
        filters[:from] = from if date == from.to_date
        filters[:to] = to if date == to.to_date
        business_day(date).number_of_working_hours filters
      end

      working_hours_per_day.sum.round(2) * sign
    end

    def add_working_hours to, number_of_hours
      raise ArgumentError, 'number_of_hours must not be negative' if number_of_hours < 0
      to = cast_time(to, :start)
      rolling_timestamp = roll_forward(to)
      remaining_hours = number_of_hours

      until (bday = business_day(rolling_timestamp)).include?(rolling_timestamp + remaining_hours.hours)
        remaining_hours -= bday.number_of_working_hours(from: rolling_timestamp)
        rolling_timestamp = at_beginning_of_next_business_day(rolling_timestamp)
      end

      rolling_timestamp + remaining_hours.hours
    end

    # @param from [Date, Time] if it's a date, it's handled as the beginning of the day
    # @param to [Date, Time] if it's a date, it's handled as the end of the day
    # @return [Float] the number of working days between the given dates.
    def working_days_between from, to
      working_hours_between(from, to) / max_working_hours_in_a_day.to_f
    end

    # @param to [Date, Time]
    # @param number_of_days [Integer, Float]
    # @return [Date, Time] The result of adding the number_of_days to the given date. If a Date is given returns a Date, otherwise if a Time is given returns a Time.
    def add_working_days to, number_of_days
      result = add_working_hours(to, number_of_days * max_working_hours_in_a_day)
      to.is_a?(Date) ? result.to_date : result
    end

    # Snaps the date to the beginning of the next business day, unless it is already within the working hours.
    #
    # @param date [Date, Time]
    def roll_forward date
      bday = business_day(date)
      if bday.include?(date)
        date
      elsif bday.starts_after?(date)
        bday.at_beginning
      else
        roll_forward date.tomorrow.beginning_of_day
      end
    end

    # Snaps the date to the beginning of the next business day.
    def at_beginning_of_next_business_day date
      roll_forward date.tomorrow.beginning_of_day
    end

    def holiday? date_or_time
      @holidays.include?(date_or_time.to_date)
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

    def business_day date
      dow = date.strftime '%a'
      BusinessDay.new date, (holiday?(date) ? EmptyWorkingHours.new : @working_hours[dow])
    end

    def max_working_hours_in_a_day
      @working_hours.values.map(&:quantity).max
    end
  end
end
