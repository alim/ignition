########################################################################
# Provide shared macros for testing user accounts
########################################################################
shared_context 'subscription_setup' do

  # Subscription setup -------------------------------------------------
        let(:create_subscriptions) {
                5.times.each { FactoryGirl.create(:subscription) }
        }

        # Stripe setup -------------------------------------------------------

end

########################################################################
# This module provides test helpers for setting up interactions with
# the stripe service for subscriptions.
########################################################################
module SubscriptionTestHelpers

  # Create plan
  def create_plan(plan_id, name, amount, interval, currency)
    Stripe.api_key = ENV['API_KEY']

    begin
      stripe_plan = Stripe::Plan.create(
      :amount => amount,
      :interval => interval,
      :name => name,
      :currency => currency,
      :id => plan_id
     )

    rescue  Stripe::InvalidRequestError => e
      raise e
      return nil
    end
 end

  # Delete a plan
  def delete_plan(plan_id)
    Stripe.api_key = ENV['API_KEY']

    begin
      stripe_plan = Stripe::Plan.retrieve(plan_id)
      stripe_plan.delete

    rescue  Stripe::InvalidRequestError => e
      raise e
      return nil
    end

    return stripe_plan
  end

  # Create coupon
  def create_coupon(coupon_code, coupon_percent_off, coupon_duration, coupon_duration_months)

    Stripe.api_key = ENV['API_KEY']

    begin
      stripe_coupon = Stripe::Coupon.create(
      :percent_off => coupon_percent_off,
      :duration => coupon_duration,
      :duration_in_months => coupon_duration_months,
      :id => coupon_code
     )

    rescue  Stripe::InvalidRequestError => e
      raise e
      return nil
    end

   return stripe_coupon
 end
  # Delete a coupon
  def delete_coupon(coupon_id)
    Stripe.api_key = ENV['API_KEY']

    begin
      stripe_coupon = Stripe::Coupon.retrieve(coupon_id)
      stripe_coupon.delete

    rescue  Stripe::InvalidRequestError => e
      raise e
      return nil
    end

    return stripe_coupon
  end
end
