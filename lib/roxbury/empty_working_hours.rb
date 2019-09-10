module Roxbury
  # Null object version of WorkingHours for holidays and other non working days
  class EmptyWorkingHours < WorkingHours
    def initialize
      super begins_at: 0, ends_at: 0
    end

    def include? _timestamp
      false
    end

    def starts_after? _timestamp
      false
    end

    def ends_before? _timestamp
      false
    end

    def non_working?
      true
    end
  end
end
