require 'json'
require 'faye/websocket'


module SlackRTMReceiver

  # Websocket client for the RTM session
  class Session

    attr_reader :logger
    attr_reader :self_uid
    attr_reader :websocket
    alias_method :ws, :websocket
    attr_reader :last_timestamp
    alias_method :ts, :last_timestamp

    def initialize
      @logger = SlackRTMReceiver.logger
      logger.debug 'Initializing Session...'
      reset_vars
    end

    def reset_vars
      @self_uid = nil
      @websocket = nil
      @last_timestamp = nil
      @ping = nil
      @stats = {}
    end

    # Start RTM websocket session
    # @param json [String] rtm.start response from Starter
    # @return [Boolean] false if a session is already up
    def start(json)
      if ws
        logger.warn 'RTM session start requested, but already running. Ignoring...'
        return false
      end
      h = parse_rtm_start_res(json)
      @self_uid = h[:self_id]
      logger.info "I am Slack ID: #{self_uid}. Connecting to websocket...\n URL: #{h[:url]}"
      opts = {ping: 60}
      @websocket = Faye::WebSocket::Client.new(h[:url], nil, opts)

      ws.on :open do
        logger.debug 'Websocket opened'
        touch_ts
      end

      ws.on :message do |ws_event|
        touch_ts
        event = JSON.parse(ws_event.data, {symbolize_names: true})
        case event[:type]
        when 'hello'
          hello_handler(event)
        when 'pong'
          pong_handler(event)
        else
          run_event_handlers(event)
        end
        @stats[:events_received] ||= 0
        @stats[:events_received] += 1
      end

      ws.on :close do |ws_event|
        logger.warn 'RTM session closed'
        cleanup
      end
      
      return true
    end

    # Send RTM event
    # @param event [Hash] RTM event; 'id' will be added automatically
    # @return [Hash] the event that was sent
    def send_event(event)
      return nil unless alive?
      event[:id] = new_event_id
      ws.send(JSON.fast_generate(event))
      logger.info "Event sent with id: #{event[:id]} type: #{event[:type]}"
      logger.debug "Sent event: #{event}"
      return event
    end

    # True if RTM session is alive
    def alive?
      return true if ws && ts
      return false
    end

    # Idle for how long?
    # @return [Float] seconds
    def idle_time
      return 0 unless alive?
      return Time.now - ts
    end

    # Send RTM ping
    # @param timeout [Fixnum] timeout in seconds
    # @return [Boolean] true if pinged
    def ping(timeout = 5)
      if @ping
        logger.debug 'RTM ping requested, but another was recently sent. Ignoring...'
        return false
      end
      event = send_event({type: 'ping', time: Time.now.to_f})
      return false unless event
      timer = EM::Timer.new(timeout) do
        logger.warn "RTM ping timed out: threshold #{timeout} sec"
        close
      end
      event[:em_timer] = timer
      @ping = event
      @stats[:pings_sent] ||= 0
      @stats[:pings_sent] += 1
      return true
    end

    # Ping if idle for more than set seconds
    # @param sec [Fixnum] idle time in seconds
    # @return [Boolean] true if pinged
    def ping_if_idle(sec = 10)
      return false if idle_time < sec
      ping
    end

    # Return statistics
    # @param opts [Hash]
    # @return [Hash]
    def stats(opts = {})
      return nil if @stats.empty?
      secs = Time.now - @stats[:hello_time]
      secs = secs.to_i
      days = secs / 86400
      secs = secs % 86400
      hours = secs / 3600
      secs = secs % 3600
      mins = secs / 60
      secs = secs % 60
      if opts[:log]
        msg = "Statistics since #{@stats[:hello_time]} (#{days} days, #{hours} hrs, #{mins} mins, #{secs} secs)\n"
        msg << "#{@stats}"
        logger.info msg
      end
      return @stats
    end

    # Close RTM session
    def close
      ws.close if ws
    end

    private

    def parse_rtm_start_res(json)
      hash = JSON.parse(json, {symbolize_names: true})
      rtmstart_handler(hash)
      return {url: hash[:url], self_id: hash[:self][:id]}
    end

    # Handle RTM start response
    def rtmstart_handler(hash)
      logger.info 'Processing RTM.start response...'
      handlers = SlackRTMReceiver.event_handlers
      handlers.each do |handler|
        handler.process_event(hash, self) if handler.type == :rtmstart
      end
    end

    # Handle RTM hello
    def hello_handler(event)
      @stats[:hello_time] = Time.now
      logger.info 'Hello received, RTM session established'
    end

    # Handle RTM pong
    def pong_handler(event)
      @stats[:pongs_received] ||= 0
      @stats[:pongs_received] += 1
      if @ping.nil? || @ping[:id] != event[:reply_to]
        logger.warn "Unexpected RTM pong received\n Pong: #{event}"
        return
      end
      latency = Time.now.to_f - @ping[:time]
      logger.info "RTM pong received, ping latency: #{'%.5f' % latency} sec"
      @ping[:em_timer].cancel
      @ping = nil
      @stats[:last_ping_latency] =  latency
    end

    # Run matching handlers
    def run_event_handlers(event)
      logger.debug "Received event: #{event}"
      return unless event[:type]
      handlers = SlackRTMReceiver.event_handlers
      handlers.each do |handler|
        handler.process_event(event, self) if handler.type == event[:type].to_sym
      end
    end

    # Get new RTM event ID
    def new_event_id
      @stats[:events_sent] ||= 0
      return @stats[:events_sent] += 1
    end

    # Update last timestamp
    def touch_ts
      @last_timestamp = Time.now
    end

    # Reset instance variables
    def cleanup
      stats({log: true})
      reset_vars
      logger.warn 'RTM session closed'
    end

  end

end
