module LeadZeppelin
  module APNS
    class Gateway
      HOST = 'gateway.push.apple.com'
      PORT = 2195
      DEFAULT_TIMEOUT = 10

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
          @ssl_socket.write notification.payload
#          sleep 2
          error_response = @ssl_socket.read_nonblock 6

          Logger.warn "error response: #{error_response.inspect}"
          Logger.thread 'e'
          error = ErrorResponse.new error_response
          reconnect
        rescue IO::WaitReadable
          Logger.thread 'x'
        rescue Errno::EPIPE => e
          Logger.warn 'gateway connection returned broken pipe, attempting reconnect and retrying...'
          Logger.thread 'f'
          reconnect
          retry
        end
      end

    end
  end
end