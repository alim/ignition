########################################################################
# This module provides test helpers for setting up interactions with
# the stripe service.
########################################################################
module StripeTestHelpers

  # Get a Stripe card token for usage in test cases
  def get_token(cardname, cardnum, expmonth, expyear, cvcvalue)
    Stripe.api_key = ENV['API_KEY']
    begin
      token = Stripe::Token.create(
        card: {
          name: cardname,
          number: cardnum,
          exp_month: expmonth,
          exp_year: expyear,
          cvc: cvcvalue
        }
      )
    rescue Stripe::CardError => e
      raise e
    end
    return token
  end

  # CUSTOMER HELPERS --------------------------------------------------

  # Create a new customer based on a stripe token
  def create_customer(token, email)
    Stripe.api_key = ENV['API_KEY']
    begin
      customer = Stripe::Customer.create(
        :description => "Test Stripe Customer for #{email}",
        :card => token
      )
    rescue  Stripe::CardError => e
      raise e
    end

    return customer
  end

  # Delete stripe customer
  def delete_customer(customer)
    return unless customer
    Stripe.api_key = ENV['API_KEY']

    begin
      cu = Stripe::Customer.retrieve(customer.id)
      response = cu.delete
    rescue  Stripe::CardError => e
      raise e
    end

    return response
  end

  # PLAN HELPERS ------------------------------------------------------

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
    return unless plan_id
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

  ## COUPON HELPERS ---------------------------------------------------

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
    return unless coupon_id
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
