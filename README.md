# LeadZeppelin

Fast, threaded client for the Apple Push Notification Service.

## Installation

Lead Zeppelin requires Ruby 1.9. It is tested on MRI. Because it uses threads, it probably runs better on JRuby and Rubinius, but has not yet been tested (feedback welcome).

Add this line to your application's Gemfile:

    gem 'lead_zeppelin'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install lead_zeppelin

## Usage

Require the gem, set threads to throw exceptions (optional, but recommended for now):

    require 'lead_zeppelin'
    Thread.abort_on_exception = true
    
Instantiate a new client and configure it by adding the block of code to handle error responses, and . Provide client.on\_error _before adding applications_.

    client = LeadZeppelin::APNS::Client.new do |c|
      c.on_error do |error_response|
        puts "Apple sent back an error response: #{error_response.inspect}"
      end
      
      # You can provide .p12 files too! p12: File.read('./yourapp.p12')
      c.add_application :your_app_identifier, pem: File.read('./yourapp.pem')
    end

## Polling

Add a poller to read messages via a method of your choosing:

    # Poll every second, join parent (main) thread so it doesn't close
    
    client.poll(1, join_parent_thread: true) do |c|
      c.message :demoapp, 'YOUR_DEVICE_TOKEN_GOES_HERE', "testing!"
    end

If you already have the generated JSON payload, you can inform the message sender to not encode to JSON:

    c.message :demoapp, 'YOUR_DEVICE_TOKEN_GOES_HERE', '{"aps":{"alert":"Now Playing: Dazed and Confused"}}', raw: true

# Logging

LeadZeppelin#logger takes a Logger class:

    require 'logger'
    LeadZeppelin.logger = Logger.new(STDERR)

To watch the thread flow, pass an IO to LeadZeppelin#thread_logger (but not a Logger):

    LeadZeppelin.thread_logger = STDERR

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## TODO

* *TESTING*
* Gateway and sandbox mode
* Way to handle errors asynchronously using a pool
* Performance and concurrency speedups
* Edge cases
* Documentation (code level and regular)
* Length checking for payload, possibly an auto truncating feature
* Research Celluloid and Celluloid::IO integration (waiting on [this ticket](https://github.com/celluloid/celluloid-io/pull/11))