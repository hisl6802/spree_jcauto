module Spree
  module Admin
    class RootController < Spree::Admin::BaseController
      #Is this setting up the location where the admin is redirected upon 
      skip_before_filter :authorize_admin

      def index
        redirect_to admin_root_redirect_path
      end

      protected

      def admin_root_redirect_path
        spree.admin_orders_path
      end
    end
  end
end
