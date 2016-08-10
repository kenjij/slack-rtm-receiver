# slack-rtm-receiver

[![Gem Version](https://badge.fury.io/rb/slack-rtm-receiver.svg)](https://badge.fury.io/rb/slack-rtm-receiver) [![Code Climate](https://codeclimate.com/github/kenjij/slack-rtm-receiver/badges/gpa.svg)](https://codeclimate.com/github/kenjij/slack-rtm-receiver)

A Ruby gem. It connects to [Slack](https://slack.com/) [Real Time Messaging API](https://api.slack.com/rtm) to receive events. Runs on EventMachine.

## Requirements

- Ruby 2.0.0 <=
- [eventmachine](https://github.com/eventmachine/eventmachine) 1.0 <=
- [em-http-request](https://github.com/igrigorik/em-http-request) 1.1 <=
- [faye-websocket](https://github.com/faye/faye-websocket-ruby) 0.8 <=

## Getting Started

### Install

```
$ gem install slack-rtm-receiver
```

### Use

```ruby
require 'slack-rtm-receiver'
```

Create an object to respond to received events. You can subclass **EventHandler**.

```ruby
class MyHandler < SlackRTMReceiver::EventHandler
  def process_event(event, session)
    if event[:text] == 'hi'
      res_event = {
        type: 'message',
        channel: event[:channel],
        text: 'Hi!'
      }
      session.send_event(res_event)
    end
  end
end
SlackRTMReceiver.add_event_handler(MyHandler.new)
```

Or, you can pass a block. The following works the same as above.

```ruby
SlackRTMReceiver::EventHandler.add_type('message') do |event, session|
  if event[:text] == 'hi'
    res_event = {
      type: 'message',
      channel: event[:channel],
      text: 'Hi!'
    }
    session.send_event(res_event)
  end
end
```

Start the reactor to connect to Slack.

```ruby
opts = {token: 'xoxb-1234abcd5678efgh'}
SlackRTMReceiver::Reactor.run(opts)
```
