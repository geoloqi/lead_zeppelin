module LeadZeppelin
  module APNS
    class GatewayPool < SizedQueue
      attr_accessor :total
      
      def initialize(max)
        @total = 0
        super
      end
    end
  end
end