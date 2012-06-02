module LeadZeppelin
  module APNS
    class Application
      CONNECTION_POOL_SIZE = 2
      CONNECTION_POOL_TIMEOUT = 5

      def initialize(name, opts={})
        @name = name

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

        cp_args = {size:    (opts[:connection_pool_size] || CONNECTION_POOL_SIZE), 
                   timeout: (opts[:connection_pool_timeout] || CONNECTION_POOL_TIMEOUT)}

        @gateway_connection_pool = ConnectionPool.new(cp_args) do
          Gateway.new @ssl_context, opts[:connection_opts] || {}
        end
      end

      def message(device_id, message)
        @gateway_connection_pool.with_connection { |conn| conn.write Notification.new(device_id, message).packaged_enhanced_notification }
      end
    end
  end
end