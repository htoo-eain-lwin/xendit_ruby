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
        unless params[:payment_request_id] || params[:invoice_id]
          raise Errors::ValidationError, 'Either payment_request_id or invoice_id is required'
        end

        validate_required_params!(params, %w[reason])
      end

      def build_create_body(params)
        params.slice(
          :payment_request_id, :invoice_id, :reference_id, :currency,
          :amount, :reason, :metadata
        ).compact
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