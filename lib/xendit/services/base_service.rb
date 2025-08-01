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

        # Handle date filters
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

      def validate_required_params!(params, required_keys)
        missing_keys = required_keys - params.keys.map(&:to_s)
        return if missing_keys.empty?

        raise Errors::ValidationError, "Missing required parameters: #{missing_keys.join(', ')}"
      end
    end
  end
end
