# Roxbury

A Ruby library for handling business days calculations, e.g., working days/hours between two dates, add working days/hours to a date, etc.

[![Build Status](https://travis-ci.org/eeng/roxbury.svg?branch=master)](https://travis-ci.org/eeng/roxbury)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'roxbury'
```

And then execute:

    $ bundle

## Usage

```ruby
calendar = Roxbury::BusinessCalendar.new(
  working_hours: {
    'Mon' => 9..17,
    'Tue' => 9..17,
    'Wed' => 9..17,
    'Thu' => 9..17,
    'Fri' => 9..17,
    'Sat' => 9..13
  }
)

calendar.working_days_between(Date.new(2019, 8, 1), Date.new(2019, 8, 5))
# => 3.5

calendar.add_working_days(Date.new(2019, 8, 3), 1)
# => Date.new(2019, 8, 5)

calendar.add_working_days(Time.new(2019, 8, 3, 9, 0), 1)
# => Time.new(2019, 8, 5, 13, 0)

calendar.working_hours_between(Time.new(2019, 8, 2, 8, 0), Time.new(2019, 8, 3, 14, 0))
# => 12

calendar.roll_forward(Time.new(2019, 8, 4))
# => Time.new(2019, 8, 5, 9, 0)
```

Please refer to the tests in `spec/roxbury/business_calendar_spec.rb` for more examples.

### Holidays

You can specify the list of holidays in the constructor:

```ruby
calendar = Roxbury::BusinessCalendar.new(
  working_hours: Hash.new(9..17),
  holidays: [Date.new(2019, 12, 25)]
)

calendar.working_days_between(Date.new(2019, 12, 24), Date.new(2019, 12, 26))
# => 2.0
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/eeng/roxbury. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## Code of Conduct

Everyone interacting in the Roxbury project’s codebases and issue trackers is expected to follow the [code of conduct](https://github.com/eeng/roxbury/blob/master/CODE_OF_CONDUCT.md).
