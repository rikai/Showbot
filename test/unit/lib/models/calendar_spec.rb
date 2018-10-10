require 'rspec'

require File.join Dir.pwd, 'lib/models/calendar.rb'

describe Calendar::GoogleCalendar do
  before(:example) do
    @calendar_id = 'googlecalendarid'
    @google_calendar_service = double('Google Calendar Service')
    @google_calendar = Calendar::GoogleCalendar.new(@calendar_id, @google_calendar_service)
  end

  it 'gets events from the Google Calendar API' do
    start_time = DateTime.parse('2015-03-07T04:00:00+00:00')
    end_time = DateTime.parse('2015-03-07T05:00:00+00:00')
    api_results = double(:data => double(:items => [
      double('event', {
        :summary => 'LIVE: Event',
        :start => double(:date_time => start_time),
        :end => double(:date_time => end_time)
      })
    ]))

    allow(@google_calendar_service).to receive(:list_events) { api_results }

    events = @google_calendar.events
    expect(events.length).to eq 1
    expect(events[0].summary).to eq 'Event'
    expect(events[0].start_time).to eq start_time
    expect(events[0].end_time).to eq end_time
  end
end

describe Calendar::NullCalendar do
  before(:example) do
    @null_calendar = Calendar::NullCalendar.new
  end

  it 'returns an empty list of events' do
    expect(@null_calendar.events).to be_empty
  end
end

describe Calendar::CalendarEvent do
  before(:context) do
    @event = Calendar::CalendarEvent.new(
      'Event',
      DateTime.parse('2015-03-07T04:00:00+00:00'),
      DateTime.parse('2015-03-07T05:00:00+00:00'),
    )
  end

  it 'covers a datetime in it' do
    compare_to = DateTime.parse('2015-03-07T-04:30:00+00:00')
    expect(@event.covers? compare_to).to be true
  end

  it 'covers the start time' do
    compare_to = DateTime.parse('2015-03-07T-04:00:00+00:00')
    expect(@event.covers? compare_to).to be true
  end

  it 'does not cover a the end time' do
    compare_to = DateTime.parse('2015-03-07T-05:00:00+00:00')
    expect(@event.covers? compare_to).to be false
  end

  it 'does not cover a datetime before it' do
    compare_to = DateTime.parse('2015-03-07T-03:30:00+00:00')
    expect(@event.covers? compare_to).to be false
  end

  it 'does not cover a datetime after it' do
    compare_to = DateTime.parse('2015-03-07T-05:30:00+00:00')
    expect(@event.covers? compare_to).to be false
  end

  it 'is after a time before it' do
    compare_to = DateTime.parse('2015-03-07T-03:30:00+00:00')
    expect(@event.after? compare_to).to be true
  end

  it 'is not after a time after it' do
    compare_to = DateTime.parse('2015-03-07T-05:30:00+00:00')
    expect(@event.after? compare_to).to be false
  end

  it 'is not after a time after it starts but before it ends' do
    compare_to = DateTime.parse('2015-03-07T-04:30:00+00:00')
    expect(@event.after? compare_to).to be false
  end

  it 'is not after the start time' do
    compare_to = DateTime.parse('2015-03-07T-04:00:00+00:00')
    expect(@event.after? compare_to).to be false
  end
end
