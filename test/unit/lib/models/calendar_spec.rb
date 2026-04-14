require 'rspec'

require File.join Dir.pwd, 'lib/models/calendar.rb'

# Calendar module is only defined when the IRC gems (google-apis-calendar_v3,
# chronic_duration) are installed. Skip the entire spec if they are not.
unless defined?(Calendar)
  RSpec.describe 'Calendar (skipped — IRC gems not installed)' do
    it('is skipped') { skip 'google-apis-calendar_v3 / chronic_duration not available' }
  end
  return
end

describe Calendar::GoogleCalendar do
  before(:example) do
    @google_config = {
      :app_name => 'TestBot',
      :app_version => '1.0.0',
      :calendar_id => 'googlecalendarid',
      :api_key => 'googlecalendarapikey'
    }
    @service = double('Google Calendar Service')

    @google_calendar = Calendar::GoogleCalendar.new(@google_config, @service)
  end

  it 'gets events from the Google Calendar API' do
    start_time = DateTime.parse('2015-03-07T04:00:00+00:00')
    end_time   = DateTime.parse('2015-03-07T05:00:00+00:00')

    event = double(
      'event',
      summary: 'LIVE: Event',
      start:   double(date_time: start_time),
      end:     double(date_time: end_time)
    )
    result = double(items: [event])

    expect(@service).to receive(:list_events).and_return(result)

    events = @google_calendar.events
    expect(events.length).to eq 1
    expect(events[0].summary).to eq 'Event'
    expect(events[0].start_time).to eq start_time
    expect(events[0].end_time).to eq end_time
  end

  it 'returns an empty array when there are no events' do
    result = double(items: nil)
    allow(@service).to receive(:list_events).and_return(result)

    expect(@google_calendar.events).to eq []
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
    compare_to = DateTime.parse('2015-03-07T04:30:00+00:00')
    expect(@event.covers? compare_to).to be true
  end

  it 'covers the start time' do
    compare_to = DateTime.parse('2015-03-07T04:00:00+00:00')
    expect(@event.covers? compare_to).to be true
  end

  it 'does not cover the end time' do
    compare_to = DateTime.parse('2015-03-07T05:00:00+00:00')
    expect(@event.covers? compare_to).to be false
  end

  it 'does not cover a datetime before it' do
    compare_to = DateTime.parse('2015-03-07T03:30:00+00:00')
    expect(@event.covers? compare_to).to be false
  end

  it 'does not cover a datetime after it' do
    compare_to = DateTime.parse('2015-03-07T05:30:00+00:00')
    expect(@event.covers? compare_to).to be false
  end

  it 'is after a time before it' do
    compare_to = DateTime.parse('2015-03-07T03:30:00+00:00')
    expect(@event.after? compare_to).to be true
  end

  it 'is not after a time after it' do
    compare_to = DateTime.parse('2015-03-07T05:30:00+00:00')
    expect(@event.after? compare_to).to be false
  end

  it 'is not after a time that falls inside it' do
    compare_to = DateTime.parse('2015-03-07T04:30:00+00:00')
    expect(@event.after? compare_to).to be false
  end

  it 'is not after the start time' do
    compare_to = DateTime.parse('2015-03-07T04:00:00+00:00')
    expect(@event.after? compare_to).to be false
  end
end
