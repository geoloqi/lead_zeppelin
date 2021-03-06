module LeadZeppelin
  module APNS
    class Gateway
      HOST         = 'gateway.push.apple.com'
      SANDBOX_HOST = 'gateway.sandbox.push.apple.com'

      PORT                = 2195
      DEFAULT_TIMEOUT     = 10
      DEFAULT_SELECT_WAIT = 0.3

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
            socket = TCPSocket.new (@opts[:host] || HOST), (@opts[:port] || PORT)
            socket.setsockopt Socket::SOL_SOCKET, Socket::SO_KEEPALIVE, true

            ssl_socket = OpenSSL::SSL::SSLSocket.new socket, @ssl_context

            ssl_socket.sync_close = true # when ssl_socket is closed, make sure the regular socket closes too.

            ssl_socket.connect

            # FIXME TODO CHECK FOR EOFError HERE instead of in process_error

            @socket = socket
            @ssl_socket = ssl_socket
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

      def process_error(notification=nil)
        begin
          error_response = @ssl_socket.read_nonblock 6
          error = ErrorResponse.new error_response, notification

          Logger.warn "error: #{error.code}, #{error.identifier.inspect}, #{error.message}"
          Logger.thread 'e'

          reconnect

          if !@opts[:notification_error_block].respond_to?(:call)
            Logger.warn "You have not implemented an on_notification_error block. This could lead to your account being banned from APNS. See the APNS docs"
          else
            @opts[:notification_error_block].call(error)
          end

        rescue EOFError
          # FIXME put in a certificate error pre-check and perhaps an error block for handling this.
          # A better solution is the remove the application altogether from the client..
          # Sometimes this just means that the socket has disconnected. Apparently Apple does that too.
          #
          Logger.info "socket has closed for #{@opts[:application_identifier]}, reconnecting"
          reconnect
        rescue IO::WaitReadable
          # No data to read, continue
          Logger.thread 'g'
        end
      end

      def write(notification)
        Logger.thread 'w'

        begin
          process_error

          @ssl_socket.write notification.payload

          read, write, error = IO.select [@ssl_socket], [], [@ssl_socket], (@opts[:select_wait] || DEFAULT_SELECT_WAIT)

          if !error.nil? && !error.first.nil?
            Logger.error "IO.select has reported an unexpected error. Reconnecting, sleeping a bit and retrying"
            sleep 1
            reconnect
          end

          if !read.nil? && !read.first.nil?
            process_error(notification)
            return false
          end

        rescue Errno::EPIPE => e
          Logger.warn 'gateway connection returned broken pipe, attempting reconnect and retrying'
          Logger.thread 'f'
          reconnect
          retry
        end

        true
      end

    end
  end
end