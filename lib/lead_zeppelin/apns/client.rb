module LeadZeppelin
  module APNS
    class Client
      CLIENT_THREADS = 10
      DEFAULT_POLL_FREQUENCY = 1
      
      def initialize(opts={}, &configure)
        @semaphore = Mutex.new
        @opts = opts
        self.instance_eval &configure

        # FIXME
        @thread_count = Queue.new
        (opts[:client_threads] || CLIENT_THREADS).times {|t| @thread_count << t}
      end

      attr_accessor :applications

      def poll(frequency=DEFAULT_POLL_FREQUENCY, opts={}, &block)
        @cycle_thread = Thread.new {
          loop do
            self.instance_eval &block
            sleep frequency
          end
        }
        
        @cycle_thread.join if opts[:join_parent_thread] == true
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

      def message(app_name, device_id, message, opts={})
        # FIXME
        t = @thread_count
        @applications[app_name].message device_id, message, opts
        @thread_count << t
      end
    end
  end
end