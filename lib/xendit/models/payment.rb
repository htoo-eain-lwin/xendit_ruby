module Xendit
  module Models
    class Payment < Base
      STATUSES = %w[PENDING SUCCEEDED FAILED].freeze

      private

      def initialize_attributes
        %w[
          id amount status country created updated currency metadata
          customer_id reference_id payment_method description failure_code
          payment_detail channel_properties payment_request_id items
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

      # Get payment method type
      def payment_method_type
        payment_method&.dig('type')
      end

      # Get channel code
      def channel_code
        case payment_method_type
        when 'EWALLET'
          payment_method&.dig('ewallet', 'channel_code')
        when 'DIRECT_DEBIT'
          payment_method&.dig('direct_debit', 'channel_code')
        when 'OVER_THE_COUNTER'
          payment_method&.dig('over_the_counter', 'channel_code')
        when 'VIRTUAL_ACCOUNT'
          payment_method&.dig('virtual_account', 'channel_code')
        when 'QR_CODE'
          payment_method&.dig('qr_code', 'channel_code')
        when 'CARD'
          'CARD'
        end
      end

      # Check if payment has payment details
      def has_payment_detail?
        !payment_detail.nil? && !payment_detail.empty?
      end

      # Get specific payment detail field
      def payment_detail_field(field)
        payment_detail&.dig(field.to_s)
      end

      # Check if payment has items
      def has_items?
        items.is_a?(Array) && !items.empty?
      end

      # Get total items count
      def items_count
        has_items? ? items.length : 0
      end
    end
  end
end
