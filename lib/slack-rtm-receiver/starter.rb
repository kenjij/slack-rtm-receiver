require 'em-http'


module SlackRTMReceiver

  # HTTP client to call rtm.start
  class Starter

    # Create and start a Starter
    # @param session [SlackRTMReceiver::Session]
    # @return [SlackRTMReceiver::Starter]
    def self.start(session, opts = {})
      starter = self.new(opts)
      starter.start(session)
      return starter
    end

    attr_reader :logger
    attr_accessor :options

    # @return [Boolean]
    def started?
      return true if @is_starting
      return true if @session && @session.alive?
      return false
    end

    # @param opts [Hash] options for Slack web API rtm.start
    def initialize(opts)
      @logger = SlackRTMReceiver.logger
      logger.debug 'Initializing Starter...'
      @options = opts
      @is_starting = false
      @session = nil
    end

    # @param session [SlackRTMReceiver::Session]
    def start(session)
      if started?
        logger.debug 'Start requested but already running. Ignoring...'
        return nil
      end
      @is_starting = true
      @session = session
      logger.debug 'Starter is calling rtm.start...'
      baseurl = 'https://slack.com/api/rtm.start'
      http = EM::HttpRequest.new(baseurl).get(query: @options, redirects: 5)
      http.callback do
        callback(http, session)
        @is_starting = false
      end
      http.errback do
        errback(http)
        @is_starting = false
      end
    end

    private

    # EM::HttpRequest callback handler
    def callback(http, session)
      status = http.response_header.status
      raise "Web API rtm.start failed: received HTTP status code #{status}" unless status == 200
      logger.info 'Recived rtm.start response'
      session.start(http.response)
    end

    # EM::HttpRequest error callback handler
    def errback(http)
      raise "Web API rtm.start failed: #{http.error}"
    end

  end

end
