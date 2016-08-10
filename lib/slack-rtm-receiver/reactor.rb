require 'eventmachine'


module SlackRTMReceiver

  class Reactor

    # Start reactor
    # @param opts [Hash] options for Slack web API rtm.start
    def self.run(opts)
      logger = SlackRTMReceiver.logger
      logger.warn "SlackRTMReceiver ver. #{Version} loaded, Reactor starting..."
      EM.run do
        session = Session.new
        starter = Starter.start(session, opts)

        # life check
        EM.add_periodic_timer(15) do
          session.alive? ? session.ping_if_idle : starter.start(session)
        end

        # statistics check
        EM.add_periodic_timer(3600) do
          session.stats({log: true}) if session.alive?
        end
      end
      logger.warn 'Reactor stopped'
    end

  end

end
