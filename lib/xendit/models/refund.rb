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

      # Check if refund has fee
      def has_refund_fee?
        !refund_fee_amount.nil? && refund_fee_amount.positive?
      end

      # Check if refund was requested by customer
      def customer_requested?
        reason == 'REQUESTED_BY_CUSTOMER'
      end

      # Check if refund was due to fraud
      def fraudulent?
        reason == 'FRAUDULENT'
      end

      # Check if refund was due to duplicate
      def duplicate?
        reason == 'DUPLICATE'
      end

      # Check if refund was due to cancellation
      def cancellation?
        reason == 'CANCELLATION'
      end

      # Get net refund amount (after fees)
      def net_refund_amount
        return amount unless has_refund_fee?

        amount - refund_fee_amount
      end
    end
  end
end
