module Xendit
  module Services
    class PaymentService < BaseService
      # List payments by payment method ID
      def list_by_payment_method(payment_method_id, params = {})
        path = "/v2/payment_methods/#{payment_method_id}/payments"
        query_params = build_list_params(params.slice(
          :payment_request_id, :reference_id, :status, :limit, :after_id, :before_id,
          :created_gte, :created_lte, :updated_gte, :updated_lte
        ))

        response = client.get(path, query_params)

        {
          data: response['data']&.map { |payment| Models::Payment.new(payment) } || [],
          has_more: response['has_more'] || false,
          links: response['links'] || []
        }
      end

      # Simulate payment (test mode only)
      def simulate(payment_method_id, amount:)
        validate_required_params!({ amount: amount }, %w[amount])

        path = "/v2/payment_methods/#{payment_method_id}/payments/simulate"
        body = { amount: amount }

        response = client.post(path, body)

        {
          status: response['status'],
          message: response['message']
        }
      end

      private

      def build_list_params(params)
        cleaned_params = super(params)

        # Handle date range parameters with proper bracketed format
        %w[created updated].each do |field|
          if cleaned_params["#{field}_gte"]
            cleaned_params["#{field}[gte]"] = cleaned_params.delete("#{field}_gte")
          end
          if cleaned_params["#{field}_lte"]
            cleaned_params["#{field}[lte]"] = cleaned_params.delete("#{field}_lte")
          end
        end

        cleaned_params
      end
    end
  end
end
