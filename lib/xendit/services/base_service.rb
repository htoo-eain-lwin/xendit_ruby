module Xendit
  module Services
    class BaseService
      def initialize(client)
        @client = client
      end

      private

      attr_reader :client

      def build_list_params(params)
        cleaned_params = params.compact

        # Handle date filters with proper bracketed notation
        %w[created updated].each do |field|
          cleaned_params["#{field}[gte]"] = cleaned_params.delete("#{field}_gte") if cleaned_params["#{field}_gte"]
          cleaned_params["#{field}[lte]"] = cleaned_params.delete("#{field}_lte") if cleaned_params["#{field}_lte"]
        end

        cleaned_params
      end

      def validate_required_params!(params, required_keys)
        missing_keys = required_keys - params.keys.map(&:to_s)
        return if missing_keys.empty?

        # Create specific error messages that match the test patterns
        unless missing_keys.size == 1
          raise Errors::ValidationError, "Missing required parameters: #{missing_keys.join(', ')}"
        end

        key = missing_keys.first
        raise Errors::ValidationError, "#{key} is required"
      end

      def validate_enum_param!(param_name, value, allowed_values)
        return if allowed_values.include?(value)

        raise Errors::ValidationError,
              "#{param_name} must be one of: #{allowed_values.join(', ')}, got: #{value}"
      end

      def validate_payment_method_type!(type)
        allowed_types = %w[CARD EWALLET DIRECT_DEBIT OVER_THE_COUNTER VIRTUAL_ACCOUNT QR_CODE]
        validate_enum_param!('type', type, allowed_types)
      end

      def validate_reusability!(reusability)
        allowed_values = %w[ONE_TIME_USE MULTIPLE_USE]
        validate_enum_param!('reusability', reusability, allowed_values)
      end

      def validate_currency!(currency)
        allowed_currencies = %w[IDR PHP USD THB MYR VND]
        validate_enum_param!('currency', currency, allowed_currencies)
      end

      def validate_country!(country)
        allowed_countries = %w[ID PH TH MY VN]
        validate_enum_param!('country', country, allowed_countries)
      end

      def validate_customer_type!(type)
        allowed_types = %w[INDIVIDUAL BUSINESS]
        validate_enum_param!('customer type', type, allowed_types)
      end
    end
  end
end
