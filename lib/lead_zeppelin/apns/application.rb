module LeadZeppelin
  module APNS
    class Application
      CONNECTION_POOL_SIZE = 5
      CONNECTION_POOL_TIMEOUT = 5

      attr_reader :name

      def initialize(name, opts={})
        @name = name
        @opts = opts

        @ssl_context = OpenSSL::SSL::SSLContext.new

        if opts[:p12]
          pem = OpenSSL::PKCS12.new opts[:p12], opts[:p12_pass]
          @ssl_context.cert = pem.certificate
          @ssl_context.key  = pem.key
        elsif opts[:pem]
          @ssl_context.cert = OpenSSL::X509::Certificate.new opts[:pem]
          @ssl_context.key  = OpenSSL::PKey::RSA.new opts[:pem], opts[:pem_pass]
        else
          raise ArgumentError, 'opts[:p12] or opts[:pem] required'
        end
      end

      def connect
        cp_args = {size:    (@opts[:connection_pool_size] || CONNECTION_POOL_SIZE),
                   timeout: (@opts[:connection_pool_timeout] || CONNECTION_POOL_TIMEOUT)}

        @gateway_connection_pool = ConnectionPool.new(cp_args) do
          Gateway.new @ssl_context, (@opts[:gateway_opts] || {}).merge(error_block: @opts[:error_block], application_name: @name)
        end
      end

      def message(device_id, message, opts={})
        connect if @gateway_connection_pool.nil?

        @gateway_connection_pool.with_connection do |gateway|
          gateway.write Notification.new(device_id, message, opts)
        end

        true
      end
    end
  end
end