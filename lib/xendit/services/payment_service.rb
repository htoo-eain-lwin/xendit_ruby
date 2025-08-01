module Xendit
  module Services
    class PaymentService < BaseService
      # List payments by payment method ID
      def list_by_payment_method(payment_method_id, params = {})
        path = "/v2/payment_methods/#{payment_method_id}/payments"
        query_params = build_list_params(params)

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
    end
  end
end