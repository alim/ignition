# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

# Use jQuery, and setup the Stripe publishable key for usage with 
# the API. Then proceed to setting up the new account form.
jQuery ->
	Stripe.setPublishableKey($('meta[name="pub_key"]').attr('content'))	
	stripe.setupForm()

# Create a new Javascript object to accept the stripe information
stripe =

	# Helper function to setup the new stripe form. It disables the
	# the standard submit button and uses it to redirect the form
	# to Stripe.com
  setupForm: ->
    $('.stripe_form').submit ->
      $('input[type=submit]').attr('disabled', true)
      if $('#card_number').length
        stripe.processCard()
        false
      else
        true
  
  # The proceesCard function will read the values from the form
  # template and submit them to Stripe. It registers a callback
  # function stripe.handleStripeResponse with the createToken
  # method.
  processCard: ->
	  card =
	    number: $('#card_number').val()
	    cvc: $('#card_code').val()
	    expMonth: $('#card_month').val()
	    expYear: $('#card_year').val()
	    name: $('#cardholder_name').val()
    Stripe.createToken(card, stripe.handleStripeResponse)

  # Function to handle the response from Stripe. If we get an error
  # We display the error in a twitter-bootstrap alert box. If we get
  # a positive response, we enable the standard submit button and
  # send the Stripe credit card token.
  handleStripeResponse: (status, response) ->
    if status == 200
      # alert "Response=#{response.id}"
      if $('#account_stripe_cc_token').length
        $('#account_stripe_cc_token').val(response.id)
      if $('#order_stripe_cc_token').length
        $('#order_stripe_cc_token').val(response.id)
      $('.stripe_form')[0].submit()
    else
      $('#stripe_error').html ->
      	return '<p class="alert">' + response.error.message + '</p>'
      $('input[type=submit]').attr('disabled', false)
