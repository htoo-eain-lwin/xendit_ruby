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
        raise Errors::ValidationError, 'Missing required parameters: amount' if amount.nil?

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
        cleaned_params = params.compact

        # Handle date range parameters with proper bracketed format
        # Convert symbol keys to string keys and transform them
        transformed_params = {}

        cleaned_params.each do |key, value|
          key_str = key.to_s
          case key_str
          when 'created_gte'
            transformed_params['created[gte]'] = value
          when 'created_lte'
            transformed_params['created[lte]'] = value
          when 'updated_gte'
            transformed_params['updated[gte]'] = value
          when 'updated_lte'
            transformed_params['updated[lte]'] = value
          else
            transformed_params[key] = value
          end
        end

        transformed_params
      end
    end
  end
end
