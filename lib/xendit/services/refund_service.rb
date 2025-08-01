module Xendit
  module Services
    class RefundService < BaseService
      # Create refund
      def create(params)
        validate_create_params!(params)

        body = build_create_body(params)
        headers = build_headers(params)

        response = client.post('/refunds', body, headers)
        Models::Refund.new(response)
      end

      # Get refund by ID
      def get(id, headers = {})
        path = "/refunds/#{id}"
        response = client.get(path, {}, build_headers(headers))
        Models::Refund.new(response)
      end

      private

      def validate_create_params!(params)
        # Either payment_request_id or invoice_id is required
        unless params[:payment_request_id] || params[:invoice_id]
          raise Errors::ValidationError, 'Either payment_request_id or invoice_id is required'
        end

        # Reason is always required
        validate_required_params!(params, %w[reason])

        # Validate reason is one of the allowed values
        allowed_reasons = %w[FRAUDULENT DUPLICATE REQUESTED_BY_CUSTOMER CANCELLATION OTHERS]
        return if allowed_reasons.include?(params[:reason])

        raise Errors::ValidationError, "reason must be one of: #{allowed_reasons.join(', ')}"
      end

      def build_create_body(params)
        params.slice(
          :payment_request_id, :invoice_id, :reference_id, :currency,
          :amount, :reason, :metadata
        ).compact

        # Ensure amount is present for CARD transactions (if determinable)
        # Note: This would require additional context about the original payment method type
      end

      def build_headers(params)
        return {} if params.nil?

        headers = {}

        # Handle standard Xendit headers
        headers['idempotency-key'] = params[:idempotency_key] if params[:idempotency_key]
        headers['for-user-id'] = params[:for_user_id] if params[:for_user_id]

        # Pass through any other headers directly
        params.each do |key, value|
          key_str = key.to_s
          next if %w[idempotency_key for_user_id].include?(key_str)

          headers[key_str] = value
        end

        headers
      end
    end
  end
end
