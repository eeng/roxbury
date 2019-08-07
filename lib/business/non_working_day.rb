module Business
  class NonWorkingDay < Day
    def initialize dow
      super begins_at: 0, ends_at: 0, dow: dow
    end

    def include? _timestamp
      false
    end

    def before_start? _timestamp
      false
    end
  end
end
