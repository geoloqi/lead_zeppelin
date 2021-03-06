require 'thread'
require 'socket'
require 'openssl'
require 'multi_json'
require 'timeout'
require 'securerandom'
require_relative './apns/application'
require_relative './apns/client'
require_relative './apns/error_response'
require_relative './apns/gateway'
require_relative './apns/gateway_pool'
require_relative './apns/logger'
require_relative './apns/notification'

module LeadZeppelin
  module APNS
    def self.client=(client)
      Mutex.new.synchronize do
        @client = client
      end

      def self.client
        @client
      end
    end
  end
end