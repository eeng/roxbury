module Business
  class Day
    attr_accessor :begins_at, :ends_at

    def self.parse bday_spec, dow
      case bday_spec
      when Range
        new begins_at: bday_spec.first, ends_at: bday_spec.last, dow: dow
      when nil
        non_working_day dow
      else
        raise ArgumentError, "Business day spec not supported: #{bday_spec.inspect}"
      end
    end

    def self.non_working_day dow
      NonWorkingDay.new dow
    end

    def self.date_to_dow date
      date.strftime('%a')
    end

    def initialize begins_at:, ends_at:, dow:
      @begins_at, @ends_at, @dow = begins_at, ends_at, dow
    end

    def working_hours from: nil, to: nil
      from = from ? hours_from_midnight(from) : begins_at
      to = to ? hours_from_midnight(to) : ends_at
      [[ends_at, to].min - [from, begins_at].max, 0].max
    end

    def same_day_of_week? timestamp
      Day.date_to_dow(timestamp) == @dow
    end

    def include? timestamp
      same_day_of_week?(timestamp) && (at_beginning(timestamp)..at_end(timestamp)).cover?(timestamp)
    end

    def before_start? timestamp
      same_day_of_week?(timestamp) && timestamp < at_beginning(timestamp)
    end

    def at_beginning timestamp
      timestamp.change(hour: begins_at, min: 0, sec: 0)
    end

    def at_end timestamp
      timestamp.change(hour: [ends_at - 1, 0].max, min: 59, sec: 59)
    end

    private

    def hours_from_midnight time
      time.seconds_since_midnight / 1.0.hour
    end
  end
end
