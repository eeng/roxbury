module Business
  # Null object version of WorkingHours for holidays and other non working days
  class NoWorkingHours < WorkingHours
    def initialize
      super begins_at: 0, ends_at: 0
    end

    def include? _timestamp
      false
    end

    def starts_after? _timestamp
      false
    end
  end
end
