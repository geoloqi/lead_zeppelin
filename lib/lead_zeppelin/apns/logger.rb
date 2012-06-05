module LeadZeppelin
  module APNS
    module Logger

      module_function

      def thread(string)
        LeadZeppelin.thread_logger.print string.upcase if LeadZeppelin.thread_logger
      end

      def debug(string)
        LeadZeppelin.logger.debug(string) if LeadZeppelin.logger
      end

      def info(string)
        LeadZeppelin.logger.info(string) if LeadZeppelin.logger
      end

      def warn(string)
        LeadZeppelin.logger.warn(string) if LeadZeppelin.logger
      end

      def error(string)
        LeadZeppelin.logger.error(string) if LeadZeppelin.logger
      end

    end
  end
end