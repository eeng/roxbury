module Business
  class WorkingHours
    attr_accessor :begins_at, :ends_at

    def self.parse bday_spec
      case bday_spec
      when Range
        if bday_spec.last <= 0
          EmptyWorkingHours.new
        else
          new begins_at: bday_spec.first, ends_at: bday_spec.last
        end
      when nil
        EmptyWorkingHours.new
      else
        raise ArgumentError, "Business day spec not supported: #{bday_spec.inspect}"
      end
    end

    def initialize begins_at:, ends_at:
      @begins_at, @ends_at = begins_at, ends_at
    end

    def quantity from: nil, to: nil
      from = from ? hours_from_midnight(from) : begins_at
      to = to ? hours_from_midnight(to) : ends_at
      [[ends_at, to].min - [from, begins_at].max, 0].max
    end

    def include? timestamp
      (at_beginning(timestamp)..at_end(timestamp)).cover?(timestamp)
    end

    def starts_after? timestamp
      timestamp < at_beginning(timestamp)
    end

    def at_beginning timestamp
      timestamp.change(hour: begins_at, min: 0, sec: 0)
    end

    def at_end timestamp
      timestamp.change(hour: [ends_at - 1, 0].max, min: 59, sec: 59)
    end

    def non_working?
      false
    end

    def working_day?
      !non_working?
    end

    private

    def hours_from_midnight time
      time.seconds_since_midnight / 1.0.hour
    end
  end
end
