module Spree
  module Admin
    class CountriesController < ResourceController
    	#Not sure how this helps the program?
        def collection
          super.order(:name)
        end

    end
  end
end
