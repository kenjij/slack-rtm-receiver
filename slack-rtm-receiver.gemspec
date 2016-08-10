$LOAD_PATH.unshift(File.expand_path("../lib", __FILE__))
require 'slack-rtm-receiver/version'


Gem::Specification.new do |s|
  s.name          = 'slack-rtm-receiver'
  s.version       = SlackRTMReceiver::Version
  s.authors       = ['Ken J.']
  s.email         = ['kenjij@gmail.com']
  s.summary       = %q{Connects to Slack Real Time Messaging (RTM) API to receive events.}
  s.description   = %q{Connects to Slack Real Time Messaging (RTM) API to receive events. Runs on EventMachine. Use this gem to create your own bot by registering event handlers.}
  s.homepage      = 'https://github.com/kenjij/slack-rtm-receiver'
  s.license       = 'MIT'

  s.files         = `git ls-files`.split($/)
  s.require_paths = ["lib"]

  s.required_ruby_version = '>= 2.0.0'

  s.add_runtime_dependency "eventmachine", "~> 1.0"
  s.add_runtime_dependency "faye-websocket", "~> 0.8"
  s.add_runtime_dependency "em-http-request", "~> 1.1"
end
