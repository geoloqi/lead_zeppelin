module LeadZeppelin
  module APNS
    class Notification
      attr_accessor :device_token, :alert, :badge, :sound, :other

      def initialize(device_token, message, opts={})
        @device_token = device_token
        @opts = opts

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
        expiry = @opts[:expiry].nil? ? 1 : @opts[:expiry].to_i
        [1, (@opts[:identifier] || 0), expiry, 0, 32, packaged_token, 0, j.bytesize, j].pack("cNNcca*cca*")
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