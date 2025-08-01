module Xendit
  module Models
    class Payment < Base
      STATUSES = %w[PENDING SUCCEEDED FAILED].freeze

      private

      def initialize_attributes
        %w[
          id amount status country created updated currency metadata
          customer_id reference_id payment_method description failure_code
          payment_detail channel_properties payment_request_id
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