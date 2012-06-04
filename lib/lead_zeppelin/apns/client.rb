module LeadZeppelin
  module APNS
    class Client
      DEFAULT_POLL_FREQUENCY = 1
      
      def initialize(opts={}, &configure)
        @semaphore = Mutex.new
        @opts = opts
        self.instance_eval &configure
      end

      attr_accessor :applications

      def poll(_frequency=DEFAULT_POLL_FREQUENCY, &block)
        @cycle_thread = Thread.new {
          loop do
            self.instance_eval &block
            sleep _frequency
          end
        }
      end

      def hold_open_poll
        @cycle_thread.join
      end

      def add_application(name, opts={})
        @semaphore.synchronize do
          @applications ||= {}
          @applications[name] = Application.new name, opts
        end
      end

      def remove_application(name)
        @semaphore.synchronize do
          @applications.delete name
        end
      end

      def message(app_name, device_id, message)
        @applications[app_name].message device_id, message
      end
    end
  end
end