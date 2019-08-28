require 'benchmark'
require 'roxbury'

calendar = Roxbury::BusinessCalendar.new(working_hours: Hash.new(5..21))
puts Benchmark.measure { 100.times { calendar.add_working_days Date.today, 500 } }
