module Xendit
  module Services
    class PaymentRequestService < BaseService
      # Create payment request
      def create(params)
        validate_create_params!(params)

        body = build_create_body(params)
        headers = build_headers(params)

        response = client.post('/payment_requests', body, headers)
        Models::PaymentRequest.new(response)
      end

      # Get payment request by ID
      def get(id, headers = {})
        path = "/payment_requests/#{id}"
        response = client.get(path, {}, build_headers(headers))
        Models::PaymentRequest.new(response)
      end

      # List payment requests
      def list(params = {})
        query_params = build_list_params(params.slice(
          :id, :reference_id, :customer_id, :limit, :after_id, :before_id
        ))
        response = client.get('/payment_requests', query_params)

        {
          data: response['data']&.map { |pr| Models::PaymentRequest.new(pr) } || [],
          has_more: response['has_more'] || false
        }
      end

      # Authorize payment request (for direct debit OTP validation)
      def authorize(id, auth_code:, headers = {})
        validate_required_params!({ auth_code: auth_code }, %w[auth_code])

        path = "/payment_requests/#{id}/auth"
        body = { auth_code: auth_code }
        request_headers = build_headers(headers)

        response = client.post(path, body, request_headers)
        Models::PaymentRequest.new(response)
      end

      # Resend auth for payment request (for certain direct debit channels)
      def resend_auth(id, headers = {})
        path = "/payment_requests/#{id}/auth/resend"
        request_headers = build_headers(headers)

        response = client.post(path, {}, request_headers)
        Models::PaymentRequest.new(response)
      end

      private

      def validate_create_params!(params)
        # Either payment_method or payment_method_id is required
        if !params[:payment_method] && !params[:payment_method_id]
          raise Errors::ValidationError, 'Either payment_method or payment_method_id is required'
        end

        # Validate payment method structure if provided
        if params[:payment_method]
          required_pm_keys = %w[type reusability]
          validate_required_params!(params[:payment_method], required_pm_keys)
        end

        # Customer ID is required for direct debit and multiple use ewallets
        validate_customer_requirements!(params)
      end

      def validate_customer_requirements!(params)
        payment_method = params[:payment_method] || {}
        type = payment_method[:type]
        reusability = payment_method[:reusability]

        requires_customer = false

        # Direct debit always requires customer
        if type == 'DIRECT_DEBIT'
          requires_customer = true
        end

        # Multiple use ewallets require customer
        if type == 'EWALLET' && reusability == 'MULTIPLE_USE'
          requires_customer = true
        end

        return unless requires_customer

        if !params[:customer_id] && !params[:customer]
          raise Errors::ValidationError, 'customer_id or customer object is required for this payment method'
        end
      end

      def build_create_body(params)
        body = params.slice(
          :currency, :amount, :reference_id, :customer_id, :customer,
          :country, :description, :payment_method, :payment_method_id,
          :capture_method, :initiator, :channel_properties, :shipping_information,
          :items, :metadata
        ).compact

        # Handle customer object
        body[:customer] = build_customer_object(params[:customer]) if params[:customer]

        # Handle payment method object
        if params[:payment_method]
          body[:payment_method] = build_payment_method_object(params[:payment_method])
        end

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

        # Handle business detail
        if customer_params[:business_detail]
          customer_obj[:business_detail] = customer_params[:business_detail].slice(
            :business_name, :trading_name, :business_type, :nature_of_business,
            :business_domicile, :date_of_registration
          ).compact
        end

        customer_obj
      end

      def build_payment_method_object(payment_method_params)
        pm_obj = payment_method_params.slice(
          :type, :reusability, :reference_id, :description, :metadata
        ).compact

        # Add type-specific objects
        %w[ewallet direct_debit card over_the_counter virtual_account qr_code].each do |type|
          pm_obj[type.to_sym] = payment_method_params[type.to_sym] if payment_method_params[type.to_sym]
        end

        pm_obj
      end

      def build_headers(params)
        headers = {}
        headers['idempotency-key'] = params[:idempotency_key] if params[:idempotency_key]
        headers['for-user-id'] = params[:for_user_id] if params[:for_user_id]
        headers['with-split-rule'] = params[:with_split_rule] if params[:with_split_rule]
        headers
      end
    end
  end
end
