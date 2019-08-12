module Spree
  module Admin
    class GeneralSettingsController < Spree::Admin::BaseController
      include Spree::Backend::Callbacks

      before_action :set_store

      def index
        @excels = Excel.all
      end

      def destroy
          @excel.destroy
      end
      
      def edit
        @preferences_security = [:check_for_spree_alerts]
      end

      def update
        params.each do |name, value|
          next unless Spree::Config.has_preference? name
          Spree::Config[name] = value
        end

        current_store.update_attributes store_params

        flash[:success] = Spree.t(:successfully_updated, resource: Spree.t(:general_settings))
        redirect_to edit_admin_general_settings_path #redirects to the page in which the user just updated, which in this case would be the general settings page.
      end

      def dismiss_alert
        if request.xhr? and params[:alert_id]
          dismissed = Spree::Config[:dismissed_spree_alerts] || ''
          Spree::Config.set dismissed_spree_alerts: dismissed.split(',').push(params[:alert_id]).join(',')
          filter_dismissed_alerts
          render nothing: true
        end
      end
      #clears the cache of any files, which will slow down the website until the cache rebuilds itself.
      def clear_cache
        Rails.cache.clear
        invoke_callbacks(:clear_cache, :after)
        head :no_content
      end

      ##############################################################################
      # EXCEL UPLOADS
      ##############################################################################

      def upload
        @path = ""
      end

      # Upload excel document to populate database
      def upload_product_excel
        require 'spreadsheet'

        @excel = Excel.new(name: 'Excel_upload', parse_errors: nil, spreadsheet: params[:file])
        
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
              category = part_row[1].to_s

              #pulls out the Description from the product sheet
              #(needs to be a string and will have to work to ensure this works when putting into a text format)
              @excel.description = part_row[2].to_s

              #pulls out the Item Tax Code
              #(Not sure on this one need to figure out)
              item_tax_code = part_row[3]#what is this column numbers and letters? Just Numbers

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
              
              # @product = Product.new(name: part_name,description: descrip)
              # #redirect_to admin_product_path(@product)
              # @product.master.price = price
              # if @product.save
              #   #flash[:success] = "Product successfully saved"
              #   redirect_to edit_admin_product_url(@product)
              # else
              #   flash[:success] = "Product didn't save"
              # end
              if @excel.save
                redirect_to admin_general_settings_url
              end
          end
           # part.each do |row|
           #    #grab each name based upon the location of the data.
           #    part_name = part[0]
           #    part_name = part_name.to_int
           #    part_name = part_name.to_s
           #  end
        #render :action => :upload
      end

      # Upload excel document to populate database
      # def upload_inventory_excel
      #   begin  
      #     my_excel = Spree::Excel.new(params[:file])
      #   rescue Exception => e
      #     flash[:error] = e.message
      #   end

      #   if (my_excel)
      #     my_excel.import_inventory_file()
      #     @errors = my_excel.get_errors
      #   end
      #   if @errors && @errors.length > 0
      #     flash[:error] = "Errors in upload, see table below"
      #   end
      #   render :action => :upload
      # end

      # def upload_vendor_excel
      #   begin
      #     my_excel = Spree::Excel.new(params[:file])
      #   rescue Exception => e
      #     flash[:error] = e.message
      #   end

      #   if (my_excel)
      #     my_excel.import_vendor_file()
      #     @errors = my_excel.get_errors
      #   end
      #   if @errors && @errors.length > 0
      #     flash[:error] = "Errors in upload, see table below"
      #   end
      #   render :action => :upload
      # end

      ##############################################################################
      # EXCEL UPLOADS
      ##############################################################################

      # Handle Quickbooks uploads
      def clear_jobs
        number_of_jobs = QBWC.clear_jobs

        flash[:info] = "Removed " + number_of_jobs.to_s + " job(s)"

        redirect_to quickbooks_edit_admin_general_settings_path
      end

      # Return customer requests
      def create_customer_requests
        # Clear any existing job
        QBWC.delete_job(:add_customer)

        customer_requests = []
        Spree::User.all.each do |user|
          customer_requests <<
          {
            :customer_add_rq => {
              :customer_add => {
                :name => "#{user.bill_address ? user.bill_address.firstname : user.email} #{user.bill_address ? user.bill_address.lastname : "" }",
                :is_active => true
              }
            }
          }
        end

        # Check XML for requests
        customer_requests.each do |request|
          if !QBWC.parser.to_qbxml(request, {:validate => true})
            flash[:error] = "Request " + request + " failed."
            render :action => :quickbooks_edit
          end
        end

        # Add job if all XML passes
        QBWC.add_job(:add_customer, true, '', CustomerWorker, customer_requests)

        flash[:success] = "Customer job added."
        redirect_to quickbooks_edit_admin_general_settings_path
      end

      def create_invoice_requests
        requests = []

        # Clear any existing job
        QBWC.delete_job(:add_invoice)

        my_orders = Spree::Order.complete.where("in_quickbooks=?", false)
        # for each order, check customers, invoices, and payments
        my_orders.each do |order|
          # Add customer and order only if user attached (should always be the case)
          if order.user
            # variables -------------------------------------------------------------
            my_user = order.user
            # get address (whether shipping or billing)
            address = my_user.bill_address ? my_user.bill_address : (my_user.ship_address ? my_user.ship_address : nil)
          else
            my_user = order
            address = order.bill_address ? order.bill_address : (order.ship_address ? order.ship_address : nil)
          end
          # get name from address
          name = "#{address ? address.lastname : order.email}#{address ? ", " + address.firstname : "" }"
          full_name = "#{address ? address.firstname : order.email}#{address ? " " + address.lastname : "" }"

          # Add customer ----------------------------------------------------------
          requests <<
          {
            :customer_add_rq => {
              :customer_add => {
                :name => name,
                :is_active => true,
                :first_name => "#{address ? address.firstname : my_user.email}",
                :last_name => "#{address ? address.lastname : ""}",
                :bill_address => {
                  :addr_1 => "#{my_user.bill_address ? my_user.bill_address.address1 : ""}",
                  :addr_2 => "#{my_user.bill_address ? my_user.bill_address.address2 : ""}",
                  :city => "#{my_user.bill_address ? my_user.bill_address.city : ""}",
                  :state => "#{my_user.bill_address ? Spree::State.find(my_user.bill_address.state_id).name : ""}",
                  :postal_code => "#{my_user.bill_address ? my_user.bill_address.zipcode : ""}",
                  :country => "#{my_user.bill_address ? Spree::Country.find(my_user.bill_address.country_id).name : ""}"
                },
                :ship_address => {
                  :addr_1 => "#{my_user.ship_address ? my_user.ship_address.address1 : ""}",
                  :addr_2 => "#{my_user.ship_address ? my_user.ship_address.address2 : ""}",
                  :city => "#{my_user.ship_address ? my_user.ship_address.city : ""}",
                  :state => "#{my_user.ship_address ? Spree::State.find(my_user.ship_address.state_id).name : ""}",
                  :postal_code => "#{my_user.ship_address ? my_user.ship_address.zipcode : ""}",
                  :country => "#{my_user.ship_address ? Spree::Country.find(my_user.ship_address.country_id).name : ""}"
                },
                :phone => "#{address ? address.phone : ""}",
                :email => "#{my_user.email}",
                :sales_tax_code_ref => {
                  :full_name => "Tax"
                },
                :item_sales_tax_ref => {
                  :full_name => (address.state_id == 3577 ? "WA State Excise Tax" : "Out of State")
                }
              }
            }
          }

          # Add Order as Invoice ------------------------------------------------------

          # generate line items
          invoice_lines = []
          order.line_items.each do |item|
            invoice_lines <<
            {
              :item_ref => {
                :full_name => "inventory"
              },
              :desc => item.variant.description,
              :quantity => item.quantity,
              :amount => sprintf('%.2f', item.price)
            }
          end

          # Add shipping
          order.shipments.each do |shipment|
            invoice_lines <<
            {
              :item_ref => {
                :full_name => "Shipping"
              },
              :desc => shipment.shipping_method.name.gsub(/[^\w\s]/, ''),
              :amount => sprintf('%.2f', shipment.cost)
            }
          end

          # Add discounts
          order.adjustments.each do |promotion|
            invoice_lines <<
            {
              :item_ref => {
                :full_name => "Promotion"
              },
              :desc => promotion.label,
              :amount => sprintf('%.2f', promotion.amount).gsub("-", "")
            }
          end

          # Add invoice
          requests <<
          {
            :invoice_add_rq => {
              :invoice_add => {
                :customer_ref => {
                  :full_name => full_name
                },
                :ar_account_ref => {
                  :full_name => "Accounts Receivable"
                },
                :txn_date => order.created_at.strftime("%Y-%m-%d"),
                :ref_number => order.number,
                :bill_address => {
                  :addr_1 => "#{order.bill_address ? order.bill_address.address1 : ""}",
                  :addr_2 => "#{order.bill_address ? order.bill_address.address2 : ""}",
                  :city => "#{order.bill_address ? order.bill_address.city : ""}",
                  :state => "#{order.bill_address ? Spree::State.find(order.bill_address.state_id).name : ""}",
                  :postal_code => "#{order.bill_address ? order.bill_address.zipcode : ""}",
                  :country => "#{order.bill_address ? Spree::Country.find(order.bill_address.country_id).name : ""}"
                },
                :ship_address => {
                  :addr_1 => "#{order.ship_address ? order.ship_address.address1 : ""}",
                  :addr_2 => "#{order.ship_address ? order.ship_address.address2 : ""}",
                  :city => "#{order.ship_address ? order.ship_address.city : ""}",
                  :state => "#{order.ship_address ? Spree::State.find(order.ship_address.state_id).name : ""}",
                  :postal_code => "#{order.ship_address ? order.ship_address.zipcode : ""}",
                  :country => "#{order.ship_address ? Spree::Country.find(order.ship_address.country_id).name : ""}"
                },
                :customer_sales_tax_code_ref => {
                  :full_name => "Tax"
                },
                :invoice_line_add => invoice_lines
              }
            }
          }

          # Add payments -------------------------------------------------------------
          if order.payment_state == "paid"
            # add new payment_requests
            order.payments.each do |payment|
              requests <<
              {
                :receive_payment_add_rq => {
                  :receive_payment_add => {
                    :customer_ref => {
                      :full_name => full_name
                    },
                    :ar_account_ref => {
                      :full_name => "Accounts Receivable"
                    },
                    :txn_date => payment.created_at.strftime("%Y-%m-%d"),
                    :ref_number => payment.number,
                    :total_amount => sprintf('%.2f', payment.amount),
                    :payment_method_ref => {
                      :full_name => payment.payment_method.name
                    },
                    :deposit_to_account_ref => {
                      :full_name => "Undeposited Funds"
                    },
                    :is_auto_apply => true
                  }
                }
              }
            end # end payments.each
          end # end if payments
        end # Loop through each order

        # Check XML for requests
        requests.each do |request|
          if !QBWC.parser.to_qbxml(request, {:validate => true})
            flash[:error] = "Request " + request + " failed."
            render :action => :quickbooks_edit
          end
        end

        # Add job if all XML passes
        @orders = []
        QBWC.add_job(:add_invoice, true, '', InvoiceWorker, requests)
        my_orders.each do |order|
          @orders << order
          order.update_attribute("in_quickbooks", true)
        end

        flash[:success] = "Invoice job added. Remember to run Quickbooks Web Connector!"

        render :action => :quickbooks_edit
      end

      def quickbooks_edit
        @path = ""
      end


      private

      def store_params
        params.require(:store).permit(permitted_store_attributes)
      end

      def set_store
        @store = current_store
      end

    end
  end
end
