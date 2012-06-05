require_relative './lead_zeppelin/apns'
require_relative './lead_zeppelin/version'

module LeadZeppelin
  class << self
    attr_accessor :logger
    attr_accessor :thread_logger
  end
end