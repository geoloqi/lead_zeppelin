module LeadZeppelin
  module APNS
    class Application
      GATEWAY_POOL_SIZE = 3

      attr_reader :identifier

      def initialize(identifier, opts={})
        @identifier = identifier
        @opts = opts

        @gateway_pool = GatewayPool.new opts[:gateway_pool_size] || GATEWAY_POOL_SIZE

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

      def new_gateway
        begin
          gateway = Gateway.new @ssl_context, 
                                (@opts[:gateway_opts] || {}).merge(notification_error_block: @opts[:notification_error_block],
                                 certificate_error_block:  @opts[:certificate_error_block],
                                 application_identifier:   @identifier)

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
        end
        
        gateway
      end

      def message(device_id, message, opts={})
        if @gateway_pool.total < @gateway_pool.max
          @gateway_pool.total += 1
          Logger.info "adding new gateway connection for #{@identifier}"
          gateway = new_gateway
        else
          gateway = @gateway_pool.pop
        end

        gateway.write Notification.new(device_id, message, opts)
        @gateway_pool.push gateway
      end
    end
  end
end