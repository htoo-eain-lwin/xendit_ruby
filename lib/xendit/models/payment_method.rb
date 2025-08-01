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

      def pending?
        status == 'PENDING'
      end

      def multiple_use?
        reusability == 'MULTIPLE_USE'
      end

      def one_time_use?
        reusability == 'ONE_TIME_USE'
      end

      # Type checking methods
      def card?
        type == 'CARD'
      end

      def ewallet?
        type == 'EWALLET'
      end

      def direct_debit?
        type == 'DIRECT_DEBIT'
      end

      def over_the_counter?
        type == 'OVER_THE_COUNTER'
      end

      def virtual_account?
        type == 'VIRTUAL_ACCOUNT'
      end

      def qr_code?
        type == 'QR_CODE'
      end

      # Get the action for a specific type (AUTH, RESEND_AUTH, etc.)
      def action_for(action_type)
        return nil unless actions.is_a?(Array)

        actions.find { |action| action['action'] == action_type.to_s.upcase }
      end

      # Get all auth actions
      def auth_actions
        return [] unless actions.is_a?(Array)

        actions.select { |action| action['action'] == 'AUTH' }
      end

      # Channel code helper
      def channel_code
        case type
        when 'EWALLET'
          ewallet&.dig('channel_code')
        when 'DIRECT_DEBIT'
          direct_debit&.dig('channel_code')
        when 'OVER_THE_COUNTER'
          over_the_counter&.dig('channel_code')
        when 'VIRTUAL_ACCOUNT'
          virtual_account&.dig('channel_code')
        when 'QR_CODE'
          qr_code&.dig('channel_code')
        when 'CARD'
          'CARD'
        end
      end
    end
  end
end
