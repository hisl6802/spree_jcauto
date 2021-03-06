module Spree
  module Admin
    class ReturnItemsController < ResourceController
    	#updates the database to include the part that was taken out given that the part was returned.
      def location_after_save
        url_for([:edit, :admin, @return_item.customer_return.order, @return_item.customer_return])
      end
    end
  end
end
