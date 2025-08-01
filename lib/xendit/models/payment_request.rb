module Xendit
  module Models
    class PaymentRequest < Base
      STATUSES = %w[REQUIRES_ACTION PENDING SUCCEEDED FAILED AWAITING_CAPTURE].freeze

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
    end
  end
end
