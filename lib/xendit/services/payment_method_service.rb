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
        response = client.get(path, {}, build_headers(headers))
        Models::PaymentMethod.new(response)
      end

      # List payment methods
      def list(params = {})
        query_params = build_list_params(params.slice(
          :type, :reusability, :reference_id, :customer_id,
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

        response = client.patch(path, body, build_headers(headers))
        Models::PaymentMethod.new(response)
      end

      # Expire payment method
      def expire(id, params = {})
        path = "/v2/payment_methods/#{id}/expire"
        query_params = params.slice(:success_return_url, :failure_return_url).compact
        headers = build_headers(params)

        full_path = query_params.empty? ? path : "#{path}?#{URI.encode_www_form(query_params)}"
        response = client.post(full_path, {}, headers)
        Models::PaymentMethod.new(response)
      end

      # Authorize payment method (for account linking)
      def authorize(id, auth_code:, headers = {})
        validate_required_params!({ auth_code: auth_code }, %w[auth_code])

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

        # Validate type-specific requirements
        case params[:type]
        when 'DIRECT_DEBIT'
          validate_required_params!(params, %w[customer_id]) unless params[:customer]
          validate_required_params!(params, %w[direct_debit])
        when 'EWALLET'
          if params[:reusability] == 'MULTIPLE_USE'
            validate_required_params!(params, %w[customer_id]) unless params[:customer]
          end
          validate_required_params!(params, %w[ewallet])
        when 'CARD'
          validate_required_params!(params, %w[card])
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

        if customer_params[:individual_detail]
          customer_obj[:individual_detail] = customer_params[:individual_detail].slice(
            :given_names, :surname, :nationality, :place_of_birth,
            :date_of_birth, :gender
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