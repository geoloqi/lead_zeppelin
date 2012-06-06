module LeadZeppelin
  module APNS
    class Notification
      attr_reader :device_token, :identifier, :expiry

      def initialize(device_token, message, opts={})
        @device_token = device_token
        @opts = opts
        
        @identifier = @opts[:identifier] || SecureRandom.random_bytes(4)
        @identifier = @identifier.to_s

        @expiry = @opts[:expiry].nil? ? 1 : @opts[:expiry].to_i

        if message.is_a?(Hash)
          other = message.delete(:other)
          @message = {aps: message}
          @message.merge!(other) if other
        elsif message.is_a?(String)
          @message = {aps: {alert: message}}
        else
          raise ArgumentError, "notification message must be hash or string"
        end
      end

      def payload
        [1, @identifier, @expiry, 0, 32, packaged_token, 0, message_json.bytesize, message_json].pack("cA4Ncca*cca*")
      end

      def packaged_token
        [device_token.gsub(/[\s|<|>]/,'')].pack('H*')
      end

      def message_json
        @message_json ||= MultiJson.encode @message
      end
    end
  end
end