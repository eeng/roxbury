module Roxbury
  RSpec.describe BusinessCalendar do
    context 'constructor' do
      it 'specifying the working hours with ranges per day of week' do
        calendar = BusinessCalendar.new(
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

      it 'must specify at least one working day' do
        raise_error = raise_error(ArgumentError, /must specify at least one working day/)
        expect { BusinessCalendar.new }.to raise_error
        expect { BusinessCalendar.new(working_hours: {'Mon' => 0..0}) }.to raise_error
        expect { BusinessCalendar.new(working_hours: {'Mon' => -5..0}) }.to raise_error
      end
    end

    context 'working_hours_between' do
      let(:calendar) do
        BusinessCalendar.new(
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
        calendar = BusinessCalendar.new(
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

      it 'should work with Date instances' do
        expect_working_hours calendar, '2019-08-09', '2019-08-09', 16
        expect_working_hours calendar, '2019-08-10', '2019-08-10', 8
      end

      def expect_working_hours calendar, from, to, expected_hours
        expect(calendar.working_hours_between(parse_date_or_time(from), parse_date_or_time(to))).to eq(expected_hours)
      end
    end

    context 'add_working_hours' do
      let(:calendar) do
        BusinessCalendar.new(
          working_hours: {
            'Mon' => 5..21,
            'Tue' => 5..21,
            'Wed' => 5..21,
            'Thu' => 5..21,
            'Fri' => 5..21,
            'Sat' => 5..13
          },
          holidays: [Date.parse('2000-01-01')]
        )
      end

      it 'when the result is on the same day' do
        add_working_hours calendar, '2000-02-22 06:05', 0, '2000-02-22 06:05'
        add_working_hours calendar, '2000-02-22 06:05', 5, '2000-02-22 11:05'
        add_working_hours calendar, '2000-02-22 06:05', 0.5, '2000-02-22 06:35'
      end

      it 'when the result is on the next day' do
        add_working_hours calendar, '2000-02-22 20:30', 1, '2000-02-23 05:30'
        add_working_hours calendar, '2000-02-22 12:00', 15, '2000-02-23 11:00'
      end

      it 'when the given timestamp is before the start of a business_day' do
        add_working_hours calendar, '2000-02-22 04:00', 1, '2000-02-22 06:00'
        add_working_hours calendar, '2000-02-22 04:00', 6, '2000-02-22 11:00'
      end

      it 'when the given timestamp is after the end of a business_day' do
        add_working_hours calendar, '2000-02-22 23:00', 6, '2000-02-23 11:00'
      end

      it 'when the hours to add span multiple days' do
        add_working_hours calendar, '2000-02-18 20:00', 10, '2000-02-21 06:00'
        add_working_hours calendar, '2000-02-18 20:00', 20, '2000-02-21 16:00'
        add_working_hours calendar, '2008-02-20 12:00', 55, '2008-02-25 11:00'
      end

      it 'should handle holidays' do
        add_working_hours calendar, '1999-12-31 20:00', 7, '2000-01-03 11:00'
        add_working_hours calendar, '2000-01-01 12:00', 6, '2000-01-03 11:00'
      end

      it 'some weird calendars' do
        calendar = BusinessCalendar.new(
          working_hours: {
            'Mon' => 8..18,
            'Wed' => 7..17,
            'Fri' => 9..19
          }
        )
        add_working_hours calendar, '2019-08-01 00:00', 160, '2019-09-09 08:00'
        add_working_hours calendar, '2019-08-01 00:00', 300, '2019-10-11 09:00'

        calendar = BusinessCalendar.new(
          working_hours: Hash.new(0..24)
        )
        add_working_hours calendar, '2000-02-22 00:00', 23.5, '2000-02-22 23:30'
      end

      it 'works with Date instances' do
        add_working_hours calendar, '2000-02-22', 1, '2000-02-22 06:00'
      end

      it 'should be complementary with working_hours_between' do
        calendar = BusinessCalendar.new(
          working_hours: {
            'Mon' => 8..17,
            'Wed' => 7..21,
            'Fri' => 9..18
          }
        )
        10.times do
          hours_to_add = rand(0..1000)
          from = Time.local(2019, 8, rand(1..31))
          to = calendar.add_working_hours(from, hours_to_add)
          working_hours = calendar.working_hours_between(from, to)
          expect(working_hours).to eq(hours_to_add), %(
            Failed when:
            add_working_hours(#{from}, #{hours_to_add}) => #{to}
            working_hours_between(#{from}, #{to}) => #{working_hours}
          )
        end
      end

      it 'hours to add must not be negative' do
        expect { calendar.add_working_hours(Time.now, -10) }.to raise_error(ArgumentError, /must not be negative/)
      end

      def add_working_hours calendar, to, hours, expected_time
        expect(calendar.add_working_hours(Time.parse(to), hours)).to eq(Time.parse(expected_time))
      end
    end

    context 'working_days_between' do
      let(:calendar) do
        BusinessCalendar.new(
          working_hours: {
            'Mon' => 5..21,
            'Tue' => 5..21,
            'Wed' => 5..21,
            'Thu' => 5..21,
            'Fri' => 5..21,
            'Sat' => 5..13
          },
          holidays: [Date.parse('2019-05-07')]
        )
      end

      it 'should return the number of working days between the two dates including the fractional part' do
        expect_working_days calendar, '2014-12-01', '2014-12-01', 1
        expect_working_days calendar, '2014-12-01', '2014-12-03', 3
        expect_working_days calendar, '2014-12-01', '2014-12-07', 5.5
        expect_working_days calendar, '2014-12-01', '2014-12-08', 6.5
        expect_working_days calendar, '2014-12-01', '2014-12-09', 7.5
        expect_working_days calendar, '2014-12-01', '2014-12-09', 7.5
        expect_working_days calendar, '2014-12-01', '2014-12-13', 11
        expect_working_days calendar, '2019-08-01', '2019-09-01', 24.5
        expect_working_days calendar, '2019-08-01', '2020-08-01', 288.5
      end

      it 'should handle holidays' do
        expect_working_days calendar, '2019-05-07', '2019-05-07', 0
        expect_working_days calendar, '2019-05-06', '2019-05-07', 1
        expect_working_days calendar, '2019-05-06', '2019-05-08', 2
      end

      def expect_working_days calendar, from, to, wd
        expect(calendar.working_days_between(Date.parse(from), Date.parse(to))).to eq wd
      end
    end

    context 'add_working_days' do
      let(:calendar) do
        BusinessCalendar.new(
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

      it 'should add the equivalent hours considering a day as the longest working hours in a day' do
        add_working_days calendar, '2019-08-05', 0, '2019-08-05'
        add_working_days calendar, '2019-08-05', 1, '2019-08-06'
        add_working_days calendar, '2019-08-05', 0.5, '2019-08-05'
        add_working_days calendar, '2019-08-05', 6, '2019-08-12'
        add_working_days calendar, '2019-08-10', 1, '2019-08-12'
        add_working_days calendar, '2019-08-01', 30, '2019-09-09'
        add_working_days calendar, '2019-08-01', 300, '2020-08-17'
      end

      it 'returns a time when a time is given' do
        add_working_days calendar, '2019-08-05 00:00', 0, '2019-08-05 05:00'
        add_working_days calendar, '2019-08-05 00:00', 1, '2019-08-06 05:00'
        add_working_days calendar, '2019-08-05 00:00', 0.5, '2019-08-05 13:00'
        add_working_days calendar, '2019-08-05 00:00', 6, '2019-08-12 13:00'
        add_working_days calendar, '2019-08-10 00:00', 1, '2019-08-12 13:00'
        add_working_days calendar, '2019-08-01 00:00', 30, '2019-09-09 05:00'
        add_working_days calendar, '2019-08-01 00:00', 300, '2020-08-17 13:00'
      end

      def add_working_days calendar, date, number_of_days, expected_result
        expect(calendar.add_working_days(parse_date_or_time(date), number_of_days)).to eq parse_date_or_time(expected_result)
      end
    end

    context 'roll_forward' do
      let(:calendar) do
        BusinessCalendar.new(
          working_hours: {
            'Mon' => 8..16,
            'Tue' => 9..17,
            'Fri' => 7..15
          }
        )
      end

      it 'when the datetime is already in the working period, should return the same value' do
        roll_forward '2019-08-05 08:00', '2019-08-05 08:00'
        roll_forward '2019-08-05 15:59', '2019-08-05 15:59'
        roll_forward '2019-08-06 09:00', '2019-08-06 09:00'
        roll_forward '2019-08-06 16:59', '2019-08-06 16:59'
      end

      it 'when the datetime is before the start of the business day, should return the start of the business day' do
        roll_forward '2019-08-05 00:00', '2019-08-05 08:00'
        roll_forward '2019-08-05 07:00', '2019-08-05 08:00'
        roll_forward '2019-08-06 08:30', '2019-08-06 09:00'
      end

      it 'when the datetime is after the end of the business day should return the start of the next business day' do
        roll_forward '2019-08-05 16:00', '2019-08-06 09:00'
        roll_forward '2019-08-05 16:05', '2019-08-06 09:00'
        roll_forward '2019-08-06 17:01', '2019-08-09 07:00'
      end

      it 'if a date is given returns a date' do
        roll_forward '2019-08-05', '2019-08-05'
        roll_forward '2019-08-07', '2019-08-09'
      end

      def roll_forward date, expected_result
        expect(calendar.roll_forward(parse_date_or_time(date))).to eq(parse_date_or_time(expected_result))
      end
    end

    def parse_date_or_time str
      case str.length
      when 10 then Date.parse(str)
      else Time.parse(str)
      end
    end

    it 'parse_date_or_time should return Time instance if the time part is given, otherwise should return a Date' do
      expect(parse_date_or_time('2019-08-06')).to eq Date.new(2019, 8, 6)
      expect(parse_date_or_time('2019-03-15 10:00')).to eq Time.new(2019, 3, 15, 10, 0)
    end
  end
end
