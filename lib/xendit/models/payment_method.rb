module Xendit
  module Models
    class PaymentMethod < Base
      STATUSES = %w[PENDING REQUIRES_ACTION ACTIVE INACTIVE EXPIRED FAILED].freeze
      TYPES = %w[CARD EWALLET DIRECT_DEBIT OVER_THE_COUNTER VIRTUAL_ACCOUNT QR_CODE].freeze
      REUSABILITY = %w[ONE_TIME_USE MULTIPLE_USE].freeze

      private

      def initialize_attributes
        %w[
          id business_id customer_id reference_id reusability country status
          actions type ewallet direct_debit card over_the_counter virtual_account
          qr_code description billing_information failure_code created updated
          metadata
        ].each { |attr| define_attribute(attr) }
      end

      public

      def active?
        status == 'ACTIVE'
      end

      def inactive?
        status == 'INACTIVE'
      end

      def expired?
        status == 'EXPIRED'
      end

      def failed?
        status == 'FAILED'
      end

      def requires_action?
        status == 'REQUIRES_ACTION'
      end

      def multiple_use?
        reusability == 'MULTIPLE_USE'
      end

      def one_time_use?
        reusability == 'ONE_TIME_USE'
      end
    end
  end
end
