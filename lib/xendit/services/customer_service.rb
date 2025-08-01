module Xendit
  module Services
    class CustomerService < BaseService
      # Create customer
      def create(params)
        validate_create_params!(params)

        body = build_create_body(params)
        headers = build_headers(params)

        response = client.post('/customers', body, headers)
        Models::Customer.new(response)
      end

      # Get customer by ID
      def get(id)
        path = "/customers/#{id}"
        response = client.get(path)
        Models::Customer.new(response)
      end

      private

      def validate_create_params!(params)
        required_keys = %w[reference_id type]
        validate_required_params!(params, required_keys)

        if params[:type] == 'INDIVIDUAL' && !params[:individual_detail]
          raise Errors::ValidationError, 'individual_detail is required for INDIVIDUAL type'
        end

        if params[:type] == 'BUSINESS' && !params[:business_detail]
          raise Errors::ValidationError, 'business_detail is required for BUSINESS type'
        end
      end

      def build_create_body(params)
        body = params.slice(:reference_id, :type, :email, :mobile_number).compact

        if params[:individual_detail]
          body[:individual_detail] = params[:individual_detail].slice(
            :given_names, :surname, :nationality, :place_of_birth,
            :date_of_birth, :gender
          ).compact
        end

        if params[:business_detail]
          body[:business_detail] = params[:business_detail].slice(
            :business_name, :trading_name, :business_type,
            :nature_of_business, :business_domicile, :date_of_registration
          ).compact
        end

        body
      end

      def build_headers(params)
        headers = {}
        headers['idempotency-key'] = params[:idempotency_key] if params[:idempotency_key]
        headers
      end
    end
  end
end