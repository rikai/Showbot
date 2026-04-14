begin
  require 'google/apis/calendar_v3'
  require 'chronic_duration'
rescue LoadError
  # IRC-only gems not available in web-only mode
  return
end
require 'tzinfo'

# The Calendar module provides access to remote calendars to JBot plugins. It
# currently pulls events from a Google Calendar as the default backend. The
# events are filtered so that only live events (where the title starts with
# 'LIVE: ') are fetched. To get a Calendar object, use
# `Calendar.new(config_data)` to get a duck-typed Calendar object that meets the
# following interface:
#
#   Calendar#events: returns an array of Calendar::CalendarEvents
#
# A Calendar::CalendarEvent object holds basic event data, and provides the
# following (read-only) attributes:
#
#   summary:    (string) The title of the event, with 'LIVE: ' prefix removed.
#   start_time: (DateTime) The start time of the event.
#   end_time:   (DateTime) The end time of the event.
module Calendar
  # Create a new Calendar object backed by the Google Calendar API v3.
  #
  # param config: A hash with the following required keys:
  #
  #   calendar_id: The Google Calendar ID of the calendar you want to use
  #   api_key:     Your API key for the Google Calendar API
  #
  def self.new(config = {})
    service = Google::Apis::CalendarV3::CalendarService.new
    service.key = config[:api_key]
    GoogleCalendar.new(config, service)
  end

  # The Calendar::GoogleCalendar class provides the default backend for Calendar
  class GoogleCalendar
    def initialize(config, service)
      @config  = config
      @service = service
    end

    # Get live events for the next 7 days.
    # Live events start with "LIVE: ".
    # Returns an array of CalendarEvent objects ordered by start time.
    def events
      now = Time.now.utc
      results = @service.list_events(
        @config[:calendar_id],
        single_events: true,
        order_by:      'startTime',
        time_min:      now.iso8601,
        time_max:      (now + 7 * 24 * 3600).iso8601,
        q:             'LIVE',
        fields:        'items(start,end,summary)'
      )

      (results.items || []).map do |event|
        summary = event.summary.gsub(/^LIVE:\s+/, '')
        CalendarEvent.new(summary, event.start.date_time, event.end.date_time)
      end
    end
  end

  # The CalendarEvent class holds data for individual events. It is provided to
  # encapsulate any variations in calendar data back-ends. It has the following
  # (read-only) attributes:
  #
  #   summary:    (string) The title of the event, with 'LIVE: ' prefix removed.
  #   start_time: (DateTime) The start time of the event.
  #   end_time:   (DateTime) The end time of the event.
  class CalendarEvent
    attr_reader :summary
    attr_reader :start_time
    attr_reader :end_time

    def initialize(summary, start_time, end_time)
      @summary    = summary
      @start_time = start_time
      @end_time   = end_time
    end

    # Determine if an event covers a time (is between event start and end)
    def covers?(time)
      start_time <= time && time < end_time
    end

    # Determine if an event starts after a time
    def after?(time)
      start_time > time
    end

    # Output a fancy breakdown of time until event
    def fancy_time_until
      ChronicDuration.output(seconds_until, :format => :long)
    end

    # Get the number of seconds until event starts
    def seconds_until
      (start_time - Time.now).to_i
    end

    # Convert start date to local string
    def start_date_to_local_string(tz = TZInfo::Timezone.get('UTC'))
      tz.strftime("%A, %-m/%-d/%Y", start_time.utc)
    end

    # Convert start time to local string
    def start_time_to_local_string(tz = TZInfo::Timezone.get('UTC'))
      tz.strftime("%-I:%M%P %Z", start_time.utc)
    end
  end
end
