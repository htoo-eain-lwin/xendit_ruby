require 'uri'
require 'base64'

module Xendit
  class Client
    def initialize(config)
      @config = config
      raise Errors::ConfigurationError, 'API key is required' unless config.valid?
    end

    def connection
      @connection ||= Faraday.new(url: @config.base_url) do |conn|
        conn.request :json
        conn.request :multipart
        conn.response :json, content_type: /\bjson$/
        conn.adapter @config.faraday_adapter

        conn.options.timeout = @config.timeout
        conn.options.open_timeout = @config.open_timeout

        # Use Basic Auth with API key as username and empty password
        conn.request :authorization, :basic, @config.api_key, ''
      end
    end

    def get(path, params = {}, headers = {})
      handle_response { connection.get(path, params, headers) }
    end

    def post(path, body = {}, headers = {})
      handle_response { connection.post(path, body, headers) }
    end

    def patch(path, body = {}, headers = {})
      handle_response { connection.patch(path, body, headers) }
    end

    def put(path, body = {}, headers = {})
      handle_response { connection.put(path, body, headers) }
    end

    def delete(path, params = {})
      handle_response { connection.delete(path, params) }
    end

    private

    def handle_response
      response = yield

      case response.status
      when 200..299
        response.body
      when 400
        handle_client_error(response)
      when 401
        raise Errors::AuthenticationError, extract_error_message(response)
      when 403
        raise Errors::ForbiddenError, extract_error_message(response)
      when 404
        raise Errors::NotFoundError, extract_error_message(response)
      when 409
        raise Errors::ConflictError, extract_error_message(response)
      when 429
        raise Errors::RateLimitError, 'Rate limit exceeded'
      when 500..599
        raise Errors::ServerError, 'Internal server error'
      else
        raise Errors::APIError, "Unexpected response status: #{response.status}"
      end
    rescue Faraday::TimeoutError
      raise Errors::TimeoutError, 'Request timeout'
    rescue Faraday::ConnectionFailed
      raise Errors::ConnectionError, 'Connection failed'
    end

    def handle_client_error(response)
      body = response.body
      error_code = body['error_code'] if body.is_a?(Hash)

      case error_code
      when 'API_VALIDATION_ERROR'
        raise Errors::ValidationError, extract_error_message(response)
      when 'DUPLICATE_ERROR'
        raise Errors::DuplicateError, extract_error_message(response)
      when 'INSUFFICIENT_BALANCE'
        raise Errors::InsufficientBalanceError, extract_error_message(response)
      when 'IDEMPOTENCY_ERROR'
        raise Errors::IdempotencyError, extract_error_message(response)
      when 'CHANNEL_NOT_ACTIVATED'
        raise Errors::ChannelNotActivatedError, extract_error_message(response)
      when 'FEATURE_NOT_ACTIVATED'
        raise Errors::FeatureNotActivatedError, extract_error_message(response)
      when 'INVALID_PAYMENT_METHOD'
        raise Errors::InvalidPaymentMethodError, extract_error_message(response)
      when 'CUSTOMER_NOT_FOUND_ERROR'
        raise Errors::CustomerNotFoundError, extract_error_message(response)
      when 'MAX_AMOUNT_LIMIT_ERROR'
        raise Errors::MaxAmountLimitError, extract_error_message(response)
      when 'ACCOUNT_ACCESS_BLOCKED'
        raise Errors::AccountAccessBlockedError, extract_error_message(response)
      else
        raise Errors::BadRequestError, extract_error_message(response)
      end
    end

    def extract_error_message(response)
      return response.reason_phrase unless response.body.is_a?(Hash)

      response.body['message'] || response.body['error_code'] || response.reason_phrase
    end
  end
end
