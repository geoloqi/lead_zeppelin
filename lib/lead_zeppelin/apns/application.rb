module LeadZeppelin
  module APNS
    class Application
      CONNECTION_POOL_SIZE = 5
      CONNECTION_POOL_TIMEOUT = 5

      attr_reader :identifier

      def initialize(identifier, opts={})
        @identifier = identifier
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

        begin
          gateway_connection_pool = ConnectionPool.new(cp_args) do
            Gateway.new @ssl_context, (@opts[:gateway_opts] || {}).merge(notification_error_block: @opts[:notification_error_block],
                                                                         certificate_error_block:  @opts[:certificate_error_block],
                                                                         application_identifier:   @identifier)
          end

        rescue OpenSSL::SSL::SSLError => e
          if e.message =~ /alert certificate unknown/
            Logger.warn "bad certificate for #{@identifier}, failed to connect"
          end
          
          if e.message =~ /alert certificate expired/
            Logger.warn "expired certificate for #{@identifier}, failed to connect"
          end

          if @opts[:certificate_error_block].nil?
            Logger.warn "removing application #{@identifier} from the client due to bad/invalid/expired certificate"
            APNS.client.remove_application @identifier
          else
            @opts[:certificate_error_block].call @identifier
          end
        else
          @gateway_connection_pool = gateway_connection_pool
        end
      end

      def message(device_id, message, opts={})
        connect if @gateway_connection_pool.nil?
        return nil if @gateway_connection_pool.nil?

        @gateway_connection_pool.with_connection do |gateway|
          gateway.write Notification.new(device_id, message, opts)
        end

        true
      end
    end
  end
end