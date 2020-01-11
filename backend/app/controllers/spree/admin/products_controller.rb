module Spree
  module Admin
    class ProductsController < ResourceController
      

      helper 'spree/products'
      #autocomplete :part_num,
      before_action :load_data, except: :index
      create.before :create_before
      update.before :update_before
      helper_method :clone_object_url

      def show
        session[:return_to] ||= request.referer
        redirect_to action: :edit
      end

      def upload
        @path = ""
      end

      def upload_product_excel
        require 'spreadsheet'
        @excel = Excel.create(name: 'Excel_upload', parse_errors: nil, spreadsheet: params[:file])

        logger.info "********* File: #{params[:file]}"
        logger.debug "********** Errors: #{@excel.errors.full_messages}"
        open_part = Spreadsheet.open(params[:file].tempfile.path)
        part = open_part.worksheet(0)
           
        #skip the first column of each row.
        part_row = part.row(1)
        part_size = part.count

        excel_row = 0
        part.each 1 do |row|
          excel_row += 1
          #Does the excel database entry need to include a spreadsheet entry each time or can the create be done with out the need for the spreadsheet column?
          if excel_row > 1
            @excel = Excel.create(name:"Multiple part upload",parse_errors: nil)
          end 

          @excel.part_num = row[0].to_i.to_s
          @excel.description = row[2].to_s
          @excel.price = row[4]
          @excel.LastPurchasecost = row[5]
          @excel.Productlength = row[6]
          @excel.Productwidth = row[7].to_s
          @excel.Productheight = row[8].to_s
          @excel.Productweight = row[9].to_s
          @excel.Application = row[11].to_s
          @excel.Location = row[12].to_s
          @excel.CrossReference = row[14].to_s

          @excel.CastingNum = row[15]
          unless @excel.CastingNum.nil?
            @excel.CastingNum = @excel.CastingNum.to_int
          end

          @excel.CoreCharge = row[16]
          @excel.ForSale = row[17].to_s
          @excel.OnlineStore = row[18].to_s
          @excel.IsActive = row[19].to_s

          @excel.Quantity = row[23]
          unless @excel.Quantity.nil?
            @excel.Quantity = @excel.Quantity.to_int
          end


          if @excel.save
            flash[:success] = "All parts sucessfully uploaded!"
          end
        end
        redirect_to admin_products_excel_index_url
      end

      def index
        session[:return_to] = request.url
        respond_with(@collection)
      end

      def excel_index
        @excels = Excel.all
        @product = Product.new
      end

      def excel_destroy
        @excel = Excel.find(params[:id])
        @excel.destroy

        flash[:success] = 'Product deleted from Excel index!'

        redirect_to admin_products_excel_index_url

      def update
        if params[:product][:taxon_ids].present?
          params[:product][:taxon_ids] = params[:product][:taxon_ids].split(',')
        end
        if params[:product][:option_type_ids].present?
          params[:product][:option_type_ids] = params[:product][:option_type_ids].split(',')
        end
        invoke_callbacks(:update, :before)
        if @object.update_attributes(permitted_resource_params)
          invoke_callbacks(:update, :after)
          flash[:success] = flash_message_for(@object, :successfully_updated)
          respond_with(@object) do |format|
            format.html { redirect_to location_after_save }
            format.js   { render layout: false }
          end
        else
          # Stops people submitting blank slugs, causing errors when they try to
          # update the product again
          @product.slug = @product.slug_was if @product.slug.blank?
          invoke_callbacks(:update, :fails)
          respond_with(@object)
        end
      end
      #Takes the product and destroys it from the inventory.
      def destroy
        @product = Product.friendly.find(params[:id])
        @product.destroy

        flash[:success] = Spree.t('notice_messages.product_deleted')

        respond_with(@product) do |format|
          format.html { redirect_to collection_url }
          format.js  { render_js_for_destroy }
        end
      end

      def clone
        @new = @product.duplicate

        if @new.save
          flash[:success] = @new
          #flash[:success] = Spree.t('notice_messages.product_cloned')
        else
          flash[:error] = Spree.t('notice_messages.product_not_cloned')
        end

        redirect_to edit_admin_product_url(@new)
      end

      def stock
        @variants = @product.variants.includes(*variant_stock_includes)
        @variants = [@product.master] if @variants.empty?
        @stock_locations = StockLocation.accessible_by(current_ability, :read)
        if @stock_locations.empty?
          flash[:error] = Spree.t(:stock_management_requires_a_stock_location)
          redirect_to admin_stock_locations_path
        end
      end

      def vendor
        @variants = @product.variants.includes(*variant_stock_includes)
        @variants = [@product.master] if @variants.empty?
        @vendors = Vendor.accessible_by(current_ability, :read)
        if @vendors.empty?
          flash[:error] = Spree.t(:vendor_management_requires_a_vendor)
          redirect_to admin_vendors_path
        end
      end

      protected

      def find_resource
        Product.with_deleted.friendly.find(params[:id])
      end

      def location_after_save
        spree.edit_admin_product_url(@product)
      end

      def load_data
        @taxons = Taxon.order(:name)
        @option_types = OptionType.order(:name)
        @tax_categories = TaxCategory.order(:name)
        @shipping_categories = ShippingCategory.order(:name)
        @excel = Excel.order(:description)
      end

      def collection
        return @collection if @collection.present?
        params[:q] ||= {}
        params[:q][:deleted_at_null] ||= "1"

        params[:q][:s] ||= "name asc"
        @collection = super
        # Don't delete params[:q][:deleted_at_null] here because it is used in view to check the
        # checkbox for 'q[deleted_at_null]'. This also messed with pagination when deleted_at_null is checked.
        if params[:q][:deleted_at_null] == '0'
          @collection = @collection.with_deleted
        end
        # @search needs to be defined as this is passed to search_form_for
        # Temporarily remove params[:q][:deleted_at_null] from params[:q] to ransack products.
        # This is to include all products and not just deleted products.
        @search = @collection.ransack(params[:q].reject { |k, _v| k.to_s == 'deleted_at_null' })
        @collection = @search.result.
              distinct_by_product_ids(params[:q][:s]).
              includes(product_includes).
              page(params[:page]).
              per(params[:per_page] || Spree::Config[:admin_products_per_page])
        @collection
      end

      def create_before
        return if params[:product][:prototype_id].blank?
        @prototype = Spree::Prototype.find(params[:product][:prototype_id])
      end

      def update_before
        # note: we only reset the product properties if we're receiving a post
        #       from the form on that tab
        return unless params[:clear_product_properties]
        params[:product] ||= {}
      end

      def product_includes
        [{ variants: [:images], master: [:images, :default_price] }]
      end

      def clone_object_url(resource)
        clone_admin_product_url resource
      end

      def current_user
        try_spree_current_user
      end

      private

      def variant_stock_includes
        [:images, stock_items: :stock_location, option_values: :option_type]
      end
    end
  end
end
