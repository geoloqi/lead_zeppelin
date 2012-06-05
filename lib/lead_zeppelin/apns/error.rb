module LeadZeppelin
  module APNS
    class ErrorResponse
      CODES = {
        0   => 'No errors encountered',
        1   => 'Processing error',
        2   => 'Missing device token',
        3   => 'Missing topic',
        4   => 'Missing payload',
        5   => 'Invalid token size',
        6   => 'Invalid topic size',
        7   => 'Invalid payload size',
        8   => 'Invalid token',
        255 => 'None (unknown)'
      }

      attr_reader :code, :identifier, :message, :notification

      def initialize(packet, notification=nil)
        command, @code, @identifier = packet.unpack 'ccA4'
        @message = CODES[@code]
        @notification = notification
      end
    end
  end
end