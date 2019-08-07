module Business
  RSpec.describe Calendar do
    it 'has a version number' do
      expect(Calendar::VERSION).not_to be nil
    end

    context 'working_hours configuration' do
      it 'with ranges per day of week' do
        calendar = Calendar.new(
          working_hours: {
            'Mon' => 5..21,
            'Sat' => 5..13
          }
        )
        expect(calendar.working_hours['Mon'].begins_at).to eq 5
        expect(calendar.working_hours['Mon'].ends_at).to eq 21
        expect(calendar.working_hours['Sat'].begins_at).to eq 5
        expect(calendar.working_hours['Sat'].ends_at).to eq 13
        expect(calendar.working_hours['Thu'].begins_at).to eq 0
        expect(calendar.working_hours['Thu'].ends_at).to eq 0
      end
    end

    context 'working_hours_between' do
      let(:calendar) do
        Calendar.new(
          working_hours: {
            'Mon' => 5..21,
            'Tue' => 5..21,
            'Wed' => 5..21,
            'Thu' => 5..21,
            'Fri' => 5..21,
            'Sat' => 5..13
          }
        )
      end

      it 'when "from" and "to" on the same business day' do
        expect_working_hours calendar, '2000-02-22 14:00', '2000-02-22 16:00', 2
        expect_working_hours calendar, '2000-02-22 14:00', '2000-02-22 16:06', 2.1
        expect_working_hours calendar, '2000-02-22 14:00', '2000-02-22 14:54', 0.9
      end

      it 'when "from" and "to" in different days' do
        expect_working_hours calendar, '2009-08-20 14:00', '2009-08-21 14:00', 16
        expect_working_hours calendar, '2009-08-20 14:06', '2009-08-21 14:00', 15.9
      end

      it 'when "from" is outside the working hours' do
        expect_working_hours calendar, '2000-02-22 04:00', '2000-02-22 06:00', 1
      end

      it 'when "to" is outside the working hours' do
        expect_working_hours calendar, '2017-12-18 20:30', '2017-12-18 21:30', 0.5
      end

      it 'when "from" and "to" are outside the working hours' do
        expect_working_hours calendar, '2017-12-18 21:30', '2017-12-18 21:30', 0
        expect_working_hours calendar, '2017-12-18 21:30', '2017-12-18 22:00', 0
        expect_working_hours calendar, '2017-12-18 22:30', '2017-12-18 21:30', 0
      end

      it 'when "from" is after "to" should negate the result' do
        expect_working_hours calendar, '2000-02-22 16:00', '2000-02-22 14:00', -2
        expect_working_hours calendar, '2009-08-21 14:00', '2009-08-20 14:00', -16
        expect_working_hours calendar, '2017-12-16 17:00', '2017-12-15 16:00', -13
      end

      it 'with holdays' do
        calendar = Calendar.new(
          working_hours: {
            'Mon' => 9..17,
            'Tue' => 9..17,
            'Wed' => 9..17
          },
          holidays: [Date.parse('2019-08-06')]
        )
        expect_working_hours calendar, '2019-08-05 9:00', '2019-08-06 17:00', 8
        expect_working_hours calendar, '2019-08-05 9:00', '2019-08-07 17:00', 16
        expect_working_hours calendar, '2019-08-06 9:00', '2019-08-07 17:00', 8
      end

      def expect_working_hours calendar, from, to, expected_hours
        expect(calendar.working_hours_between(Time.parse(from), Time.parse(to))).to eq(expected_hours)
      end
    end

    context 'add_working_hours' do
      let(:calendar) do
        Calendar.new(
          working_hours: {
            'Mon' => 5..21,
            'Tue' => 5..21,
            'Wed' => 5..21,
            'Thu' => 5..21,
            'Fri' => 5..21,
            'Sat' => 5..13
          }
        )
      end

      skip 'when the result is on the same day' do
        add_working_hours calendar, '2000-02-22 06:05', 5, '2000-02-22 11:05'
      end

      def add_working_hours calendar, to, hours, expected_time
        expect(calendar.add_working_hours(Time.parse(to), hours)).to eq(Time.parse(expected_time))
      end
    end
  end
end
