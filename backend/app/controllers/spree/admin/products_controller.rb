module Spree
  module Admin
    class ProductsController < ResourceController
      

      helper 'spree/products'

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
        if part_size <= 2

              #pulls out the name which is the part number of the product
              #(needs to be a string)
              @excel.part_num = part_row[0].to_int.to_s

              #pulls out the category from the product sheet
              #(needs to be a string given the dash in the category)
              @category = part_row[1].to_s

              #pulls out the Description from the product sheet
              #(needs to be a string and will have to work to ensure this works when putting into a text format)
              @excel.description = part_row[2].to_s

              #pulls out the Item Tax Code
              #(Not sure on this one need to figure out)
              @item_tax_code = part_row[3]#what is this column numbers and letters? Just Numbers

              #pulls out the Unit Price of the item
              #(needs to be a decimal)
              @excel.price = part_row[4]

              #pulls out the Last purchase cost
              #(needs to be a decimal)
              @excel.LastPurchasecost = part_row[5]

              #pulls out the product length (in)
              #(needs to be a decimal)
              @excel.Productlength = part_row[6]

              #pulls out the product width (in)
              #(needs to be a decimal)
              @excel.Productwidth = part_row[7].to_s

              #pulls out the product height (in)
              #(needs to be a decimal)
              @excel.Productheight = part_row[8].to_s

              #pulls out the product weight
              #(needs to be a decimal)
              @excel.Productweight = part_row[9].to_s

              #Remarks
              #(needs to be a string)
              #In my opinion this needs to be removed from the table
              remarks = part_row[10].to_s

              #application
              #(needs to be a string)
              @excel.Application = part_row[11].to_s

              #Location
              #(needs to be a string)
              @excel.Location = part_row[12].to_s

              #Condition 
              #(needs to be a string)
              condition = part_row[13].to_s

              #Cross Reference
              #(needs to be a string)
              @excel.CrossReference = part_row[14].to_s

              #Casting number
              #(needs to be an integer)
              @excel.CastingNum = part_row[15]
              unless @excel.CastingNum.nil?
                @excel.CastingNum = @excel.CastingNum.to_int
              end

              #Core Charge
              #(needs to be a decimal)
              @excel.CoreCharge = part_row[16]

              #For sale (date in which it is for sale)
              #(needs to be a string)
              @excel.ForSale = part_row[17].to_s

              #Online store
              #(needs to be a string for now)
              #I may request this to be removed it seems to be redundant at this point
              @excel.OnlineStore = part_row[18].to_s

              #IsActive
              #(needs to be a string for now)
              @excel.IsActive = part_row[19].to_s

              #Item
              #I believe I would like this to be removed
              item = part_row[20].to_s

              #location-duplicate with column [17] above.
              #(needs to be a string)
              loc = part_row[21].to_s

              #Sublocation
              #(needs to be a string)
              @excel.Sublocation= part_row[22].to_s

              #Quantity
              #(needs to be an integer)
              @excel.Quantity = part_row[23].to_int
              unless @excel.Quantity.nil?
                @excel.Quantity = @excel.Quantity.to_int
              end

               @product = Product.new
               @product.id = @excel.part_num
               @product.description = @excel.description
               @product.price = @excel.price
        end
        if @product.save
          flash[:success] = @product.description#"Everything thing is working up to this point."
        else
          flash[:success] = "I am still missing the price so uploading shouldn't work."
        end
      end

      def index
        session[:return_to] = request.url
        respond_with(@collection)
      end

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
