module Spree
  module Admin
    class VariantsIncludingMasterController < VariantsController
      #Not sure of the point of this class in the two modules.
      belongs_to "spree/product", find_by: :slug

      def model_class
        Spree::Variant
      end

      def object_name
        "variant"
      end

    end
  end
end
