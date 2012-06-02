module LeadZeppelin
  module APNS
    module Connection
      class Gateway
        include Base

        def host
          'gateway.push.apple.com'
        end

        def port
          2195
        end

        def write(payload)
          attempts = 0

          begin
            binding.pry
            @ssl_socket.write payload
          rescue Errno::EPIPE
          rescue => e
            if attempts == 1
              puts "Failed second attempt, raising exception"
              raise e
            end
            puts "Rescued SSL exception while writing: #{e}. Attempting to reconnect and resend"
            attempts = 1
            retry
          end
        end
      end
    end
  end
end