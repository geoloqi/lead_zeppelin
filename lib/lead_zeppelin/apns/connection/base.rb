module LeadZeppelin
  module APNS
    module Connection
      module Base
        def initialize(ssl_context, opts={})
          @ssl_context = ssl_context
          @opts        = opts
          connect
        end

        def connect
          @socket = TCPSocket.new((@opts[:apns_host] || host), (@opts[:apns_port] || port))
          @ssl_socket = OpenSSL::SSL::SSLSocket.new @socket, @ssl_context
          @ssl_socket.connect
        end

        def reconnect
          disconnect
          connect
        end

        def disconnect
          @ssl_socket.close
          @socket.close
        end
      end
    end
  end
end