require 'google/apis/calendar_v3'
require 'chronic_duration'
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
  # Create a new Calendar object, here a GoogleCalendar object. This method is a
  # factory method to get a Calendar duck-subtype object.
  # A Calendar object fetches a remote calendar feed. Those events can then be
  # retrieved as an array of Calendar::CalendarEvent objects.
  #
  # param config: The `config` parameter is a hash of configuration data.
  # Currently, it pulls in the parameters required to call out to the Google
  # Calendar API. A simple way to have all this set is to pass the Cinch plugin
  # config object into this method, and set all the required fields in the
  # cinchize.yml config file. The hash has the following required keys:
  #
  #   app_name:    The name of your application
  #   app_version: The version of your application
  #   calendar_id: The Google Calendar ID of the calendar you want to use
  #   api_key:     Your API key for the Google Calendar API
  #
  # The `app_name` and `app_version` fields can be arbitrary, and are for
  # Google's use. The calendar_id is of the form:
  #
  #   CALENDARIDHERE@group.calendar.google.com
  #
  # and is embedded in your calendar's URLs. The api_key must be obtained from
  # Google through their API Console at https://code.google.com/apis/console
  #
  def self.new(config = {})
    # Return a NullCalendar if the config doesn't have all of the keys that are
    # necessary to create a GoogleCalendar
    return NullCalendar.new unless (config.has_key? :api_key and
            config.has_key? :calendar_id and
            config.has_key? :app_name and
            config.has_key? :app_version)

    # Configure the client options of this Google API Client. Specifically, set
    # the app name and version as per the configuration hash.
    client_options = Google::Apis::ClientOptions.default.dup
    client_options.application_name = config[:app_name]
    client_options.application_version = config[:app_version]

    # Configure the request options of this Google API Client. Specifically,
    # this is where we'll set up OAuth, if we ever implement it. For now, this
    # can stay commented out -- it just does the default as it is.
    request_options = Google::Apis::RequestOptions.default.dup
    # request_options.authorization = nil

    # Create a CalendarService API client to read a Google Calendar.
    cal_service = Google::Apis::CalendarV3::CalendarService.new
    # Configure the API key
    cal_service.key = config[:api_key]
    # And the client and request options from above
    cal_service.client_options = client_options
    cal_service.request_options = request_options

    GoogleCalendar.new(config[:calendar_id], cal_service)
  end

  # A NullCalendar that returns no events, for use when an invalid configuration
  # is given to this module's constructor.
  class NullCalendar
    def events
        return []
    end
  end

  # The Calendar::GoogleCalendar class provides the default backend for Calendar
  class GoogleCalendar
    # param calendar_id: The Google Calendar ID of the calendar you want to use
    # param cal_service: (Google::Apis::CalendarV3::CalendarService) A Google
    #   Calendar API (V3) service object
    def initialize(calendar_id, cal_service)
      @calendar_id = calendar_id
      @cal_service = cal_service
    end

    # Get live events for the next 7 days
    # Live events start with "LIVE: "
    # Returns an array of CalendarEvent objects
    # Events are ordered by start time, ascending
    # The "LIVE: " prefix is stripped from the event summary
    def events
      results = @cal_service.list_events(
        @calendar_id,
        order_by: 'startTime',
        q: 'LIVE',
        single_events: true,
        time_max: (DateTime.now + 7).to_s,
        time_min: DateTime.now.to_s,
        fields: 'items(start,end,summary)',
      )

      results.data.items.map do |event|
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
      @summary = summary
      @start_time = start_time
      @end_time = end_time
    end

    # Determine of an event covers a time (is between event start and end)
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
    # returns: (int) Seconds until start
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
