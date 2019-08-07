module Business
  # Wraps a specific date with its working hours schedule
  class Day
    def initialize date, working_hours
      @date = date
      @working_hours = working_hours
    end

    def number_of_working_hours *args
      @working_hours.quantity *args
    end

    def same_day? timestamp
      timestamp.to_date == @date.to_date
    end

    def include? timestamp
      same_day?(timestamp) && @working_hours.include?(timestamp)
    end

    def starts_after? timestamp
      same_day?(timestamp) && @working_hours.starts_after?(timestamp)
    end

    def at_beginning
      @working_hours.at_beginning @date
    end

    def at_end
      @working_hours.at_end @date
    end
  end
end
