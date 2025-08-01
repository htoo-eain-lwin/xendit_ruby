module Xendit
  module Models
    class Customer < Base
      TYPES = %w[INDIVIDUAL BUSINESS].freeze

      private

      def initialize_attributes
        %w[
          id reference_id type individual_detail business_detail
          email mobile_number created updated
        ].each { |attr| define_attribute(attr) }
      end

      public

      def individual?
        type == 'INDIVIDUAL'
      end

      def business?
        type == 'BUSINESS'
      end
    end
  end
end
