module Xendit
  module Services
    class PaymentMethodService < BaseService
      # Create payment method
      def create(params)
        validate_create_params!(params)

        body = build_create_body(params)
        headers = build_headers(params)

        response = client.post('/v2/payment_methods', body, headers)
        Models::PaymentMethod.new(response)
      end

      # Get payment method by ID
      def get(id, headers = {})
        path = "/v2/payment_methods/#{id}"
        request_headers = build_headers(headers)
        response = client.get(path, {}, request_headers)
        Models::PaymentMethod.new(response)
      end

      # List payment methods
      def list(params = {})
        query_params = build_list_params(params.slice(
                                           :id, :type, :reusability, :reference_id, :customer_id,
                                           :limit, :after_id, :before_id
                                         ))

        response = client.get('/v2/payment_methods', query_params)

        {
          data: response['data']&.map { |pm| Models::PaymentMethod.new(pm) } || [],
          has_more: response['has_more'] || false
        }
      end

      # Update payment method
      def update(id, params, headers = {})
        path = "/v2/payment_methods/#{id}"
        body = params.slice(
          :reference_id, :description, :status, :reusability,
          :over_the_counter, :virtual_account
        ).compact

        request_headers = build_headers(headers)
        response = client.patch(path, body, request_headers)
        Models::PaymentMethod.new(response)
      end

      # Expire payment method
      def expire(id, params = {})
        path = "/v2/payment_methods/#{id}/expire"

        # Build query parameters for KTB direct debit channels
        query_params = params.slice(:success_return_url, :failure_return_url).compact
        headers = build_headers(params)

        # Add query parameters to path if present
        path += "?#{URI.encode_www_form(query_params)}" unless query_params.empty?

        response = client.post(path, {}, headers)
        Models::PaymentMethod.new(response)
      end

      # Authorize payment method (for account linking)
      def authorize(id, auth_code:, headers: {})
        raise Errors::ValidationError, 'auth_code is required' if auth_code.nil?

        path = "/v2/payment_methods/#{id}/auth"
        body = { auth_code: auth_code }
        request_headers = build_headers(headers)

        response = client.post(path, body, request_headers)
        Models::PaymentMethod.new(response)
      end

      private

      def validate_create_params!(params)
        required_keys = %w[type reusability]
        validate_required_params!(params, required_keys)

        # Validate customer requirements based on type and reusability
        validate_customer_requirements!(params)

        # Validate type-specific requirements
        validate_type_specific_requirements!(params)
      end

      def validate_customer_requirements!(params)
        type = params[:type]
        reusability = params[:reusability]

        requires_customer = false

        # Direct debit always requires customer
        requires_customer = true if type == 'DIRECT_DEBIT'

        # Multiple use ewallets require customer
        requires_customer = true if type == 'EWALLET' && reusability == 'MULTIPLE_USE'

        return unless requires_customer

        return unless !params[:customer_id] && !params[:customer]

        raise Errors::ValidationError, 'customer_id or customer object is required for this payment method'
      end

      def validate_type_specific_requirements!(params)
        type = params[:type]

        case type
        when 'DIRECT_DEBIT'
          validate_required_params!(params, %w[direct_debit])
        when 'EWALLET'
          validate_required_params!(params, %w[ewallet])
        when 'CARD'
          validate_required_params!(params, %w[card])
        when 'OVER_THE_COUNTER'
          validate_required_params!(params, %w[over_the_counter])
        when 'VIRTUAL_ACCOUNT'
          validate_required_params!(params, %w[virtual_account])
        when 'QR_CODE'
          validate_required_params!(params, %w[qr_code])
        end
      end

      def build_create_body(params)
        body = params.slice(
          :type, :reusability, :reference_id, :customer_id, :customer,
          :country, :description, :billing_information, :metadata
        ).compact

        # Add type-specific objects
        %w[ewallet direct_debit card over_the_counter virtual_account qr_code].each do |type|
          body[type.to_sym] = params[type.to_sym] if params[type.to_sym]
        end

        # Handle customer object
        body[:customer] = build_customer_object(params[:customer]) if params[:customer]

        body
      end

      def build_customer_object(customer_params)
        customer_obj = customer_params.slice(:reference_id, :type, :email, :mobile_number).compact

        # Handle individual detail
        if customer_params[:individual_detail]
          customer_obj[:individual_detail] = customer_params[:individual_detail].slice(
            :given_names, :surname, :nationality, :place_of_birth,
            :date_of_birth, :gender
          ).compact
        end

        # Handle business detail (if needed)
        if customer_params[:business_detail]
          customer_obj[:business_detail] = customer_params[:business_detail].slice(
            :business_name, :trading_name, :business_type, :nature_of_business,
            :business_domicile, :date_of_registration
          ).compact
        end

        customer_obj
      end

      def build_headers(params)
        headers = {}
        headers['idempotency-key'] = params[:idempotency_key] if params[:idempotency_key]
        headers['for-user-id'] = params[:for_user_id] if params[:for_user_id]
        headers
      end
    end
  end
end
