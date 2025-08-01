module Xendit
  module Models
    class Refund < Base
      STATUSES = %w[PENDING SUCCEEDED FAILED].freeze
      REASONS = %w[FRAUDULENT DUPLICATE REQUESTED_BY_CUSTOMER CANCELLATION OTHERS].freeze

      private

      def initialize_attributes
        %w[
          id payment_id invoice_id amount payment_method_type channel_code
          currency status country reason reference_id failure_code
          refund_fee_amount created updated metadata
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
    end
  end
end