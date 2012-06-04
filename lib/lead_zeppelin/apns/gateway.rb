module LeadZeppelin
  module APNS
    class Gateway
      HOST = 'gateway.push.apple.com'
      PORT = 2195

      def initialize(ssl_context, opts={})
        @semaphore = Mutex.new
        @ssl_context = ssl_context
        @opts        = opts

        connect
      end

      def connect
        socket = TCPSocket.new((@opts[:apns_host] || HOST), (@opts[:apns_port] || PORT))
        ssl_socket = OpenSSL::SSL::SSLSocket.new socket, @ssl_context
        ssl_socket.connect

        @semaphore.synchronize do
          @socket = socket
          @ssl_socket = ssl_socket
        end
      end

      def reconnect
        disconnect
        connect
      end

      def disconnect
        @ssl_socket.close
        @socket.close
      end

      def write(notification)
        begin
          @ssl_socket.write notification.payload

          error = @ssl_socket.read_nonblock 6
          puts "ERROR: #{error.inspect}"
          reconnect
        rescue IO::WaitReadable
        end
      end

    end
  end
end