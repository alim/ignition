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
  
end
