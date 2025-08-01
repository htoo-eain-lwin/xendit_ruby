module Xendit
  module Models
    class PaymentRequest < Base
      STATUSES = %w[REQUIRES_ACTION PENDING SUCCEEDED FAILED AWAITING_CAPTURE].freeze
      CAPTURE_METHODS = %w[AUTOMATIC MANUAL].freeze
      INITIATORS = %w[CUSTOMER MERCHANT].freeze

      private

      def initialize_attributes
        %w[
          id business_id customer_id reference_id currency amount country
          status description payment_method actions capture_method initiator
          card_verification_results created updated metadata channel_properties
          shipping_information items failure_code
        ].each { |attr| define_attribute(attr) }
      end

      public

      def successful?
        status == 'SUCCEEDED'
      end

      def failed?
        status == 'FAILED'
      end

      def pending?
        status == 'PENDING'
      end

      def requires_action?
        status == 'REQUIRES_ACTION'
      end

      def awaiting_capture?
        status == 'AWAITING_CAPTURE'
      end

      def automatic_capture?
        capture_method == 'AUTOMATIC'
      end

      def manual_capture?
        capture_method == 'MANUAL'
      end

      def customer_initiated?
        initiator == 'CUSTOMER'
      end

      def merchant_initiated?
        initiator == 'MERCHANT'
      end

      # Get the action for a specific type (AUTH, CAPTURE, etc.)
      def action_for(action_type)
        return nil unless actions.is_a?(Array)

        actions.find { |action| action['action'] == action_type.to_s.upcase }
      end

      # Get all auth actions
      def auth_actions
        return [] unless actions.is_a?(Array)

        actions.select { |action| action['action'] == 'AUTH' }
      end

      # Check if payment method is embedded or referenced
      def embedded_payment_method?
        payment_method.is_a?(Hash) && payment_method['id']
      end
    end
  end
end
