module LeadZeppelin
  module APNS
    class Gateway
      HOST = 'gateway.push.apple.com'
      PORT = 2195
      DEFAULT_TIMEOUT = 10
      DEFAULT_SELECT_WAIT = 0.5

      def initialize(ssl_context, opts={})
        Logger.thread 'g'
        @semaphore = Mutex.new
        @ssl_context = ssl_context
        @opts        = opts

        connect
      end

      def connect
        Logger.thread 's'
        begin
          timeout(@opts[:timeout] || DEFAULT_TIMEOUT) do
            socket = TCPSocket.new((@opts[:apns_host] || HOST), (@opts[:apns_port] || PORT))
            ssl_socket = OpenSSL::SSL::SSLSocket.new socket, @ssl_context
            ssl_socket.sync_close = true # when ssl_socket is closed, make sure the regular socket closes too.
            ssl_socket.connect

            @semaphore.synchronize do
              @socket = socket
              @ssl_socket = ssl_socket
            end
          end

          Logger.debug "gateway connection established"

        rescue Errno::ETIMEDOUT, Timeout::Error
          Logger.warn "gateway connection timeout, retrying"
          retry
        end
      end

      def reconnect
        Logger.info "reconnecting to gateway"
        Logger.thread 'r'
        disconnect
        connect
      end

      def disconnect
        Logger.info "disconnecting from gateway"
        Logger.thread 'd'
        @ssl_socket.close
      end

      def write(notification)
        Logger.thread 'w'
        
        begin
          # The APNS protocol is designed in such a way that you need to wait for the response to see if there was an error, 
          # but if there was no error, no acknowledgement is sent. If there is an error, the connection is also dropped, which causes 
          # messages to mysteriously fail sending without reporting (@ssl_socket.write length is the right size, closed? says false, and
          # exceptions aren't thrown). Since we (currently) need to "sleep" a bit to check for these errors anyways, I threw it in an 
          # IO.select so that we at least don't have to wait when an error response arrives. This is not ideal, but I have not found a
          # better way to catch this. Suggestions very welcome here.

          @ssl_socket.write notification.payload

          read, write, error = IO.select [@ssl_socket], [], [@ssl_socket], (@opts[:select_wait] || DEFAULT_SELECT_WAIT)

          if !error.nil? && !error.first.nil?
            Logger.error "IO.select has reported an unexpected error. Reconnecting, sleeping a bit and retrying"
            sleep 1
            reconnect
          end

          if !read.nil? && !read.first.nil?
            error_response = @ssl_socket.read_nonblock 6
            error = ErrorResponse.new error_response

            Logger.warn "error: #{error.inspect}"
            Logger.thread 'e'
            reconnect
          end

        rescue Errno::EPIPE => e
          Logger.warn 'gateway connection returned broken pipe, attempting reconnect and retrying'
          Logger.thread 'f'
          reconnect
          retry
        end
      end

    end
  end
end