# frozen_string_literal: true

# name: discourse-patrons
# about: Integrates Stripe into Discourse to allow visitors to make payments and Subscribe
<<<<<<< HEAD
# version: 2.0.0
=======
# version: 1.3.1
>>>>>>> 0b90caac2d8bd82beb147226c00417883391edcb
# url: https://github.com/rimian/discourse-patrons
# authors: Rimian Perkins

enabled_site_setting :discourse_patrons_enabled

gem 'stripe', '5.8.0'

register_asset "stylesheets/common/discourse-patrons.scss"
register_asset "stylesheets/common/discourse-patrons-layout.scss"
register_asset "stylesheets/mobile/discourse-patrons.scss"
register_svg_icon "credit-card" if respond_to?(:register_svg_icon)

register_html_builder('server:before-head-close') do
  "<script src='https://js.stripe.com/v3/'></script>"
end

extend_content_security_policy(
  script_src: ['https://js.stripe.com/v3/']
)

add_admin_route 'discourse_patrons.title', 'discourse-patrons.products'

Discourse::Application.routes.append do
  get '/admin/plugins/discourse-patrons' => 'admin/plugins#index'
  get '/admin/plugins/discourse-patrons/dashboard' => 'admin/plugins#index'
  get '/admin/plugins/discourse-patrons/products' => 'admin/plugins#index'
  get '/admin/plugins/discourse-patrons/products/:product_id' => 'admin/plugins#index'
  get '/admin/plugins/discourse-patrons/products/:product_id/plans' => 'admin/plugins#index'
  get '/admin/plugins/discourse-patrons/products/:product_id/plans/:plan_id' => 'admin/plugins#index'
  get '/admin/plugins/discourse-patrons/subscriptions' => 'admin/plugins#index'
  get '/admin/plugins/discourse-patrons/plans' => 'admin/plugins#index'
  get '/admin/plugins/discourse-patrons/plans/:plan_id' => 'admin/plugins#index'
  get 'u/:username/billing' => 'users#show', constraints: { username: USERNAME_ROUTE_FORMAT }
  get 'u/:username/subscriptions' => 'users#show', constraints: { username: USERNAME_ROUTE_FORMAT }
end

after_initialize do
  ::Stripe.api_version = "2019-11-05"
<<<<<<< HEAD
  ::Stripe.set_app_info('Discourse Patrons', version: '2.0.0', url: 'https://github.com/rimian/discourse-patrons')
=======
  ::Stripe.set_app_info('Discourse Patrons', version: '1.3.1', url: 'https://github.com/rimian/discourse-patrons')
>>>>>>> 0b90caac2d8bd82beb147226c00417883391edcb

  [
    "../lib/discourse_patrons/engine",
    "../config/routes",
    "../app/controllers/concerns/stripe",
    "../app/controllers/admin_controller",
    "../app/controllers/admin/plans_controller",
    "../app/controllers/admin/products_controller",
    "../app/controllers/admin/subscriptions_controller",
    "../app/controllers/user/subscriptions_controller",
    "../app/controllers/customers_controller",
    "../app/controllers/invoices_controller",
    "../app/controllers/patrons_controller",
    "../app/controllers/plans_controller",
    "../app/controllers/products_controller",
    "../app/controllers/subscriptions_controller",
    "../app/models/customer",
    "../app/serializers/payment_serializer",
  ].each { |path| require File.expand_path(path, __FILE__) }

  Discourse::Application.routes.append do
    mount ::DiscoursePatrons::Engine, at: 'patrons'
  end
end
