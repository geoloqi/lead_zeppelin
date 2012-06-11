module LeadZeppelin
  module APNS
    class Client
      CLIENT_THREADS = 10
      DEFAULT_POLL_FREQUENCY = 1

      def initialize(opts={}, &configure)
        Logger.info "instantiating client with options: #{opts.inspect}"
        Logger.thread 'c'
        @semaphore = Mutex.new
        @opts = opts
        @applications = {}

        self.instance_eval &configure if configure

        # FIXME
        @thread_count = Queue.new
        (opts[:client_threads] || CLIENT_THREADS).times {|t| @thread_count << t}
        
        APNS.client = self
      end

      attr_accessor :applications

      def on_notification_error(&block)
        @notification_error_block = block
      end

      def on_certificate_error(&block)
        @certificate_error_block = block
      end

      def poll(frequency=DEFAULT_POLL_FREQUENCY, opts={}, &block)
        Logger.info 'creating polling thread'
        Logger.thread 'p'
        @polling_thread = Thread.new {
          loop do
            self.instance_eval &block
            sleep frequency
          end

          Logger.thread 'polling thread running'
        }

        @polling_thread.join if opts[:join_parent_thread] == true
      end

      def hold_open_poll
        Logger.info 'attaching current thread to polling thread'
        @polling_thread.join
      end

      def add_application(name, opts={})
        Logger.info "adding application \"#{name}\""
        Logger.thread 'a'
        
        begin
          application = Application.new name, opts.merge(notification_error_block: @notification_error_block,
                                                         certificate_error_block:  @certificate_error_block)
        rescue OpenSSL::X509::CertificateError => e
          Logger.error "received a bad certificate for #{name}, not adding application"
        end

        @semaphore.synchronize do
          @applications ||= {}
          @applications[name] = application
        end
      end

      def remove_application(name)
        Logger.info "removing application \"#{name}\""
        Logger.thread 'r'
        @semaphore.synchronize do
          deleted = @applications.delete name
          Logger.warn "removing application \"#{name}\" failed! Name may be invalid." if deleted.nil?
        end
      end

      def message(app_name, device_id, message, opts={})
        Logger.debug "message: \"#{app_name}\", \"#{device_id}\", \"#{message}\""
        Logger.thread 'm'

        # FIXME
        t = @thread_count
        @applications[app_name].message device_id, message, opts
        @thread_count << t
      end
    end
  end
end