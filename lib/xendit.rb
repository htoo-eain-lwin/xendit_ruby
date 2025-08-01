require 'faraday'
require 'faraday/multipart'
require 'multi_json'
require 'base64'

require_relative 'xendit/version'
require_relative 'xendit/configuration'
require_relative 'xendit/client'
require_relative 'xendit/errors'
require_relative 'xendit/models/base'
require_relative 'xendit/models/payment'
require_relative 'xendit/models/payment_request'
require_relative 'xendit/models/payment_method'
require_relative 'xendit/models/refund'
require_relative 'xendit/models/customer'
require_relative 'xendit/services/base_service'
require_relative 'xendit/services/payment_service'
require_relative 'xendit/services/payment_request_service'
require_relative 'xendit/services/payment_method_service'
require_relative 'xendit/services/refund_service'
require_relative 'xendit/services/customer_service'

module Xendit
  class << self
    def configure
      yield(configuration)
    end

    def configuration
      @configuration ||= Configuration.new
    end

    def client
      @client ||= Client.new(configuration)
    end

    # Service accessors
    def payments
      @payments ||= Services::PaymentService.new(client)
    end

    def payment_requests
      @payment_requests ||= Services::PaymentRequestService.new(client)
    end

    def payment_methods
      @payment_methods ||= Services::PaymentMethodService.new(client)
    end

    def refunds
      @refunds ||= Services::RefundService.new(client)
    end

    def customers
      @customers ||= Services::CustomerService.new(client)
    end
  end
end
