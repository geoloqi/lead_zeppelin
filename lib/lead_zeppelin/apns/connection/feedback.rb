module LeadZeppelin
  module APNS
    module Connection
      class Feedback
        include Base

        def host
          'feedback.push.apple.com'
        end

        def port
          2196
        end

        def read
          feedback = []

          while line = @socket.gets
            f = line.strip.unpack('N1n1H140')
            feedback << [Time.at(f[0]), f[2]]
          end

          @ssl_socket.close
          @socket.close

          feedback
        end
      end
    end
  end
end