module Spree
  module Admin
    class ApplicationsController < ResourceController
      #I believe if someone is using this they get return of the function collection or technically the collection function is already present as an ...
      # instance variable and then the user or webpage uses @collection to get the current collection of ??(orders, products,etc.)
      def index
        respond_with(@collection)
      end

      private

      def collection
        return @collection if @collection.present?
        # params[:q] can be blank upon pagination
        params[:q] = {} if params[:q].blank?
        #What is super and why is it used here??
        @collection = super
        @search = @collection.ransack(params[:q])
        @collection = @search.result.order("name asc").
              page(params[:page]).
              per(Spree::Config[:properties_per_page])

        @collection
      end
    end
  end
end
