module Business
  class Day
    attr_accessor :begins_at, :ends_at

    def self.parse bday_spec
      case bday_spec
      when Range
        new begins_at: bday_spec.first, ends_at: bday_spec.last
      when nil
        non_working_day
      else
        raise ArgumentError, "Business day spec not supported: #{bday_spec.inspect}"
      end
    end

    def self.non_working_day
      new begins_at: 0, ends_at: 0
    end

    def initialize begins_at:, ends_at:
      @begins_at, @ends_at = begins_at, ends_at
    end

    def working_hours from: nil, to: nil
      from = from ? hours_from_midnight(from) : begins_at
      to = to ? hours_from_midnight(to) : ends_at
      [[ends_at, to].min - [from, begins_at].max, 0].max
    end

    private

    def hours_from_midnight time
      time.seconds_since_midnight / 1.0.hour
    end
  end
end
