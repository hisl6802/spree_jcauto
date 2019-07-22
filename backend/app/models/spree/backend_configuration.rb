module Spree
#This contains the drop down values for the backend Admin sidebar allowing the administrator to make the appropriate changes...
#this only sets the values of the sidebar when they are called a controller is required in order to ensure the appropriate functionality for the website.
  class BackendConfiguration < Preferences::Configuration
    preference :locale, :string, default: Rails.application.config.i18n.default_locale
    ORDER_TABS         ||= [:orders, :payments, :creditcard_payments,
                            :shipments, :credit_cards, :return_authorizations,
                            :customer_returns, :adjustments, :customer_details]
    PRODUCT_TABS       ||= [:products, :option_types, :properties, :prototypes,
                            :variants, :product_properties, :taxonomies,
                            :taxons]
    REPORT_TABS        ||= [:reports]
    CONFIGURATION_TABS ||= [:configurations, :general_settings, :tax_categories,
                            :tax_rates, :zones, :countries, :states,
                            :payment_methods, :shipping_methods,
                            :shipping_categories, :stock_transfers,
                            :stock_locations, :trackers, :refund_reasons,
                            :reimbursement_types, :return_authorization_reasons]
    PROMOTION_TABS     ||= [:promotions, :promotion_categories]
    USER_TABS          ||= [:users]
  end
end
