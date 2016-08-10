module SlackRTMReceiver

  def self.event_handlers=(handlers)
    @event_handlers = handlers
  end

  def self.event_handlers
    @event_handlers ||= []
  end

  def self.add_event_handler(handler)
    @event_handlers ||= []
    @event_handlers << handler
  end

  # Create objects to handle events:
  #  - subclass EventHandler, or
  #  - just create an instance and pass a block
  class EventHandler

    # Create and register a handler object by passing a block
    # @param type [String] event type
    def self.add_type(type, &block)
      handler = new(type, &block)
      SlackRTMReceiver.add_event_handler(handler)
    end

    attr_reader :type

    # Create a new handler instance
    # @param type [String] event type
    def initialize(type = :message, &block)
      @type = type
      @block = block if block_given?
    end

    # Callback method; called by SlackRTMReceiver::Session when event is received
    # @param [Hash] event data
    # @param [Object] caller object
    def process_event(event, session)
      logger = session.logger
      logger.debug "#{self.class.name} running..."
      @block.call(event, session) if @block
    end

  end

end
