########################################################################
# The Account model is used to store the Stripe.com customer_id and
# the current status of the account. The model is also responsible for
# interfacing with the Stripe.com service to store, retrieve and
# update the customer information stored there.
########################################################################
class Account
  include Mongoid::Document
  include Mongoid::Timestamps

  # Add call to strip leading and trailing white spaces from all atributes
  strip_attributes  # See strip_attributes for more information

  # CONSTANTS ---------------------------------------------------------

  # STRIPE ACCOUNT DESCRIPTION
  ACCOUNT_NAME = "Acme"

  # STATUS VALUES

  # UNKNOWN - is the default starting status
  UNKNOWN = 0

  # ACTIVE - Account has been setup, the credit card has been
  # ACTIVE and the customer identifier has been retrieved from
  # Stripe.com
  ACTIVE = 1

  # INACTIVE - The account's charge card is not valid any longer, so
  # the account has been moved to an INACTIVE state.
  INACTIVE = 2

  # CLOSED - The account has been closed is no longer active.
  CLOSED = 3

  # NO_STRIPE - The stripe account record was deleted and there is
  # no longer a stripe stored credit card associated with the account.
  NO_STRIPE = 4

  # ATTRIBUTES ---------------------------------------------------------

  field :customer_id, type: String
  field :status, type: Integer, default: UNKNOWN

  # Add non database instance variables to store the temporary
  # Stripe credit card data in memory, but not in the database.
  attr_accessor :stripe_cc_token, :cardholder_email, :cardholder_name
  attr_accessor :last4, :card_type, :expiration


  # VALIDATIONS --------------------------------------------------------
  validates_presence_of :status


  # RELATIONSHIPS ------------------------------------------------------

  embedded_in :user


  # PUBLIC INSTANCE METHODS --------------------------------------------

  #####################################################################
  # The status_str method returns the account status in string format
  #####################################################################
  def status_str
    case self.status
    when ACTIVE
      "Active"
    when INACTIVE
      "Inactive"
    when CLOSED
      "Closed"
    when NO_STRIPE
      "No Stripe Account"
    else
      "Unknown"
    end
  end

  #####################################################################
  # The get_customer method retrieves the customer information from
  # Stripe.com. It then stores some of the information in memory for
  # desplaying to the user. None of the retrieved information is stored
  # in the database. The retrieved information sets in-memory instance
  # variables for:
  #
  # * cardholder_name
  # * cardholder_email
  # * last4 - digits of the credit card
  # * expiration date - month - year format
  # * sets the account status to INACTIVE if the card is deliquent
  #####################################################################
  def get_customer
    if self.customer_id.present?

      begin
        Stripe.api_key = ENV['API_KEY']
        customer = Stripe::Customer.retrieve("#{self.customer_id}")

        if customer.respond_to?(:deleted)
          self.status = NO_STRIPE
        else
          load_customer_info(customer)
          if customer.delinquent == true
            self.status = INACTIVE
          end
        end

       rescue Stripe::StripeError => stripe_error
        logger.debug("[Account.get_customer] stripe error = #{stripe_error.message}")
        errors[:customer_id] << stripe_error.message
        return nil
      end

      return customer
    else
      return nil
     end
  end


  #####################################################################
  # The save_with_stripe will save the account record and corresponding
  # stripe customer_id in the database. The stripe_cc_token is not
  # saved since it is only useful for one transaction.
  #
  # The save_with_stripe method takes the standard params hash that is
  # passed to the create and update methods. This params hash should
  # include:
  # * stripe_cc_token
  # * cardholder_email
  #####################################################################
  def save_with_stripe(params)
    account_valid = true
    begin

      if (account_valid = is_valid(params))
        # Create a stripe customer
        Stripe.api_key = ENV['API_KEY']

        customer = Stripe::Customer.create(
          :description => "#{ACCOUNT_NAME} customer account.",
          :card => params[:account][:stripe_cc_token],
          :email => params[:cardholder_email]
        )

        load_customer_info(customer)
        self.status = ACTIVE

        # Attempt to save the record
        account_valid = self.save ? true : false
      end

    rescue Stripe::StripeError => stripe_error
      account_valid = stripe_error_handler(stripe_error, INACTIVE)
    end

    return account_valid
  end

  #####################################################################
  # The update with_stripe method will update the account record and
  # corresponding stripe customer_id in the database. The stripe_cc_token
  # is not saved since it is only useful for one transaction.
  #
  # The update_with_stripe method takes the standard params hash that is
  # passed to the create and update methods.
  #####################################################################
  def update_with_stripe(params)
    account_valid = true

    begin
      if (account_valid = is_valid(params))
        # Create a stripe customer
        Stripe.api_key = ENV['API_KEY']
        customer = Stripe::Customer.retrieve("#{self.customer_id}")

        if customer.respond_to?(:deleted)
          self.status = NO_STRIPE
        else
          update_customer_info(customer, params)

          load_customer_info(customer)

          self.status = ACTIVE

          # Attempt to save the record
          account_valid = self.save ? true : false
        end
      end

    rescue Stripe::StripeError => stripe_error
      account_valid = stripe_error_handler(stripe_error, INACTIVE)
    end

    return account_valid
  end

  #####################################################################
  # The destroy method overrides the standard destroy method for ActiveModel.
  # This version will delete Stripe.com customer account associated
  # with the stored customer_id.
  #####################################################################
  def destroy

    # Destroy the customer account on Stripe.com if the id is present.
    if self.customer_id.present?
      begin
        Stripe.api_key = ENV['API_KEY']
        customer = Stripe::Customer.retrieve("#{self.customer_id}")
        customer.delete
      rescue Stripe::StripeError => stripe_error
        logger.debug("[Account.delete] stripe error = #{stripe_error.message}")
        errors[:customer_id] << stripe_error.message

        # continue to raise the exception
        raise Stripe::StripeError, stripe_error.message
      end
     end

     super()
  end

  # PROTECTED INSTANCE METHODS ----------------------------------------
  protected

  #####################################################################
  # This helper method handles logging and setting stripe errors. It
  #####################################################################
  def stripe_error_handler(stripe_error, status=nil)
    logger.debug("[Account] stripe error = #{stripe_error.message}")
    errors[:customer_id] << stripe_error.message
    self.status = status if status
    return false
  end

  #####################################################################
  # Little helper method to update customer record with stripe and
  # contact information.
  #####################################################################
  def update_customer_info(customer, params)
    customer.card = params[:account][:stripe_cc_token]
    customer.description = "#{ACCOUNT_NAME} account for #{params[cardholder_name]}"
    customer.email = params[:cardholder_email]

    customer.save
  end

  ######################################################################
  # This helper method is used to load card and customer information
  # into the instance variables for the Account model.
  ######################################################################
  def load_customer_info(customer)
    self.customer_id = customer.id
    self.cardholder_email = customer.email

    customer_card = get_default_card(customer)

    self.cardholder_name = customer_card.name
    self.card_type = customer_card.type
    self.last4 = customer_card.last4
    self.expiration =  customer_card.exp_month.to_s +
      '/' + customer_card.exp_year.to_s
  end


  ######################################################################
  # The get_default_card is a method that will return the default card
  # associated with a customer account.
  ######################################################################
  def get_default_card(customer)
    default_card = nil

    customer.cards.each do |card|
      if card.id == customer.default_card
        default_card = card
      end
    end

    return default_card
  end

  ######################################################################
  # The is_valid helper method checks to make sure the user included
  # cardholder_name, cardholder_email, and that the stripe_cc_token
  # was returned from the Stipe.com service.
  ######################################################################
  def is_valid(params)
    account_valid = true

    if params[:cardholder_name].blank?
      errors[:cardholder_name] << "cannot be blank."
      account_valid = false
    end

    if params[:cardholder_email].blank?
      errors[:cardholder_email] << "cannot be blank."
      account_valid = false
    end

    if params[:account][:stripe_cc_token].blank?
      errors[:base] << "- Could not get a valid response from Stripe.com"
      account_valid = false
    end

    return account_valid
  end
end
