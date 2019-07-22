module Spree
  module Admin
    class TaxRatesController < ResourceController
      #loads in the current tax rates to ensure that the customer pays the appropriate tax rate when purchasing an item.
      before_action :load_data

      private

      def load_data
        @available_zones = Zone.order(:name)
        @available_categories = TaxCategory.order(:name)
        @calculators = TaxRate.calculators.sort_by(&:name)
      end
    end
  end
end
