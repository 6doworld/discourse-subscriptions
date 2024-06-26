# frozen_string_literal: true

module DiscourseSubscriptions
  module Admin
    class SubscriptionsController < ::Admin::AdminController
      include DiscourseSubscriptions::Stripe
      include DiscourseSubscriptions::Group
      before_action :set_api_key

      PAGE_LIMIT = 10

      def index
        begin
          subscription_ids = Subscription.all.pluck(:external_id)
          subscriptions = {
            has_more: false,
            data: [],
            length: 0,
            last_record: params[:last_record],
          }

          if subscription_ids.present? && is_stripe_configured?
            while subscriptions[:length] < PAGE_LIMIT
              current_set = get_subscriptions(subscriptions[:last_record])

              until valid_subscriptions =
                      find_valid_subscriptions(current_set[:data], subscription_ids)
                current_set = get_subscriptions(current_set[:data].last)
                break if current_set[:has_more] == false
              end

              subscriptions[:data] = subscriptions[:data].concat(valid_subscriptions.to_a)
              subscriptions[:last_record] = current_set[:data].last[:id] if current_set[
                :data
              ].present?
              subscriptions[:length] = subscriptions[:data].length
              subscriptions[:has_more] = current_set[:has_more]
              break if subscriptions[:has_more] == false
            end
          elsif !is_stripe_configured?
            subscriptions = nil
          end

          # Custom code
          internal_subscriptions = InternalSubscription.all
          if internal_subscriptions.present?
            subscriptions[:length] += internal_subscriptions.length
            
            internal_subscriptions.each do |internal_subscription|
              plan = ::Stripe::Price.retrieve(internal_subscription[:product_id])
              product = ::Stripe::Product.retrieve(plan[:product])
              user = ::User.find(internal_subscription.user_id)

              subs = {
                type: 'internal',
                metadata: {
                  user_id: user.id,
                  username: user.username
                }
              }

              subs[:metadata].merge!(plan[:metadata])
            
              subs.merge!(internal_subscription.attributes)
              subs[:id] = "internal_#{internal_subscription[:id]}"
              subs[:plan] = plan
              subs[:plan][:product] = product

              subs[:status] = internal_subscription[:status] == "succeeded" ? "active" : internal_subscription[:status]
              subs[:created] = internal_subscription[:created_at].to_i

              subscriptions[:data] << subs
            end
          end

          render_json_dump subscriptions
        rescue ::Stripe::InvalidRequestError => e
          render_json_error e.message
        end
      end

      def destroy
        params.require(:id)
        begin
          if params[:id].start_with?("internal_")
            internal_id = params[:id][9..-1].to_i # Returns the ID
            internal_subscription =
              InternalSubscription.where(
                id: internal_id
              ).first

            plan = ::Stripe::Price.retrieve(internal_subscription[:product_id])

            product = ::Stripe::Product.retrieve(plan[:product])

            # Mark subscription as inactive
            internal_subscription.update(status: 'cancelled')

            data = {
              id: "internal_#{internal_id}",
              plan: plan,
              product: product,
              current_period_end: internal_subscription[:next_due],
              created: internal_subscription[:created_at].to_i,
              status: 'cancelled'
            }

            # Remove groups
            group = ::Group.find_by_name(plan[:metadata][:group_name])
            group&.remove(user) if group

            render_json_dump data
          end

          refund_subscription(params[:id]) if params[:refund]
          subscription = ::Stripe::Subscription.delete(params[:id])

          customer =
            Customer.find_by(
              product_id: subscription[:plan][:product],
              customer_id: subscription[:customer],
            )

          Subscription.delete_by(external_id: params[:id])

          if customer
            user = ::User.find(customer.user_id)
            customer.delete
            group = plan_group(subscription[:plan])
            group.remove(user) if group
          end

          render_json_dump subscription
        rescue ::Stripe::InvalidRequestError => e
          render_json_error e.message
        end
      end

      private

      def get_subscriptions(start)
        ::Stripe::Subscription.list(
          expand: ["data.plan.product"],
          limit: PAGE_LIMIT,
          starting_after: start,
        )
      end

      def find_valid_subscriptions(data, ids)
        valid = data.select { |sub| ids.include?(sub[:id]) }
        valid.empty? ? nil : valid
      end

      # this will only refund the most recent subscription payment
      def refund_subscription(subscription_id)
        subscription = ::Stripe::Subscription.retrieve(subscription_id)
        invoice = ::Stripe::Invoice.retrieve(subscription[:latest_invoice]) if subscription[
          :latest_invoice
        ]
        payment_intent = invoice[:payment_intent] if invoice[:payment_intent]
        refund = ::Stripe::Refund.create({ payment_intent: payment_intent })
      end
    end
  end
end
