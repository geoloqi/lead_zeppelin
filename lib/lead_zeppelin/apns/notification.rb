module LeadZeppelin
  module APNS
    class Notification
      attr_reader :device_token, :alert, :badge, :sound, :other, :identifier, :expiry

      def initialize(device_token, message, opts={})
        @device_token = device_token
        @opts = opts
        
        @identifier = @opts[:identifier] || SecureRandom.random_bytes(4)
        @identifier = @identifier.to_s

        @expiry = @opts[:expiry].nil? ? 1 : @opts[:expiry].to_i

        if message.is_a?(Hash)
          @alert = message[:alert]
          @badge = message[:badge]
          @sound = message[:sound]
          @other = message[:other]
        elsif message.is_a?(String)
          @alert = message
        else
          raise ArgumentError, "notification message must be hash or string"
        end
      end

      def payload
        j = message_json
        [1, @identifier, @expiry, 0, 32, packaged_token, 0, j.bytesize, j].pack("cA4Ncca*cca*")
      end

      def packaged_token
        [device_token.gsub(/[\s|<|>]/,'')].pack('H*')
      end

      def message_json
        aps = {'aps'=> {} }
        aps['aps']['alert'] = @alert if @alert
        aps['aps']['badge'] = @badge if @badge
        aps['aps']['sound'] = @sound if @sound
        aps.merge!(@other) if @other
        MultiJson.encode aps
      end
    end
  end
end