module LeadZeppelin
  module APNS
    class Client
      def initialize(opts={})
        @opts = opts
      end

      attr_accessor :applications

      def add_application(name, opts={})
        @applications ||= {}
        @applications[name] = Application.new name, opts
      end

      def remove_application(name)
        @applications.delete name
      end

      def message(app_name, device_id, message)
        @applications[app_name].message device_id, message
      end

      def disconnect
        @ssl_socket.close
        @socket.close
      end
    end
  end
end