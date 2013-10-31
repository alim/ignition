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
    Stripe.api_key = ENV['API_KEY']
    
    begin
      cu = Stripe::Customer.retrieve(customer.id)
      response = cu.delete
    rescue  Stripe::CardError => e
      raise e
    end
    
    return response  
  end
end
