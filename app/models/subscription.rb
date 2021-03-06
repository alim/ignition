########################################################################
# The Subscription model holds information about a subscription plan
# that will be created on the Stripe.com service. The model includes
# enhancements for timestamps and white space stripping. Eventually,
# we would like to generalize this class via dependency injection to
# support multiple payment providers.
########################################################################
class Subscription
  include Mongoid::Document
  include Mongoid::Timestamps

  # Add call to strip leading and trailing white spaces from all atributes

  strip_attributes  # See strip_attributes for more information

  ## CONSTANTS ---------------------------------------------------------

  # The PLAN_OPTIONS is a hash of Stripe.com plan ID's associated with
  # this service. Each hash enter includes a label and an id. In the
  # future we should factor out the plan dependency into a separate
  # service class.
  PLAN_OPTIONS = {
    bronze: {label: 'Bronze Plan', plan_id: 'BRONZE'},
    silver: {label: 'Silver Plan', plan_id: 'SILVER'},
    gold: {label: 'Gold Plan', plan_id: 'GOLD'},
  }

  # SUBSCRIPTION STATUS VALUES
  TRAILING = 'trialing'
  ACTIVE = 'active'
  PAST_DUE = 'past_due'
  CANCELLED = 'cancelled'
  UNPAID = 'unpaid'
  UNKNOWN = 'unknown'

  ## ATTRIBUTES --------------------------------------------------------

  field :stripe_plan_id, type: String
  field :cancel_at_period_end, type: Boolean
  field :quantity, type: Integer
  field :sub_start, type: DateTime
  field :sub_end, type: DateTime
  field :status, type: String, default: UNKNOWN
  field :canceled_at, type: DateTime
  field :current_period_start, type: DateTime
  field :current_period_end, type: DateTime
  field :trial_start, type: DateTime
  field :trial_end, type: DateTime

  ## Non-database attribute for storing a coupon code when subscribing
  attr_accessor :coupon_code

  # Add non database instance variables to store the temporary
  # Stripe credit card data in memory, but not in the database.
  attr_accessor :stripe_cc_token, :cardholder_email, :cardholder_name
  attr_accessor :customer_id

  ## VALIDATIONS -------------------------------------------------------

  validates_presence_of :stripe_plan_id
  validates_presence_of :quantity
  validates_presence_of :sub_start
  validates_presence_of :status
  validates_presence_of :user_id

  ## RELATIONSHIPS -----------------------------------------------------

  belongs_to :user

  ## INSTANCE METHODS --------------------------------------------------

  ######################################################################
  # The plan_str returns a string that represents the name of the
  # subscription plan.
  ######################################################################
  def plan_str
    case self.stripe_plan_id
    when PLAN_OPTIONS[:bronze][:plan_id]
      PLAN_OPTIONS[:bronze][:label]
    when PLAN_OPTIONS[:silver][:plan_id]
      PLAN_OPTIONS[:silver][:label]
    when PLAN_OPTIONS[:gold][:plan_id]
      PLAN_OPTIONS[:gold][:label]
    else
      "Unknown Plan"
    end
  end

  ##########################################################################
  # The subscribe method creates or updates a Stripe subscription for a
  # given user. It then store some of the information in memory for that
  # user. The following parameters are passed to this method:
  #
  # 1) User Account
  # 2) Type of Plan
  # 3) Discount Coupon
  #
  # This method will return a subscription object.
  ##########################################################################
  def subscribe(account_user, plan_id, coupon_code)

    if account_user.customer_id.present?

      begin
        Stripe.api_key = ENV['API_KEY']

        customer = Stripe::Customer.retrieve("#{account_user.customer_id}")
        self.sub_start = DateTime.now
        self.quantity = 1
        self.stripe_plan_id = plan_id

        update_customer_subscription_info(customer, plan_id, coupon_code)

        self.status = ACTIVE
        self.save

      rescue Stripe::StripeError => stripe_error
          logger_debugger(errors, stripe_error, customer_id, "[Subscription.subscribe] error = #{stripe_error.message}")
          return nil
      end
    else
      return nil
    end

    return self
  end

  ##########################################################################
  # The cancel_subscription method cancels a Stripe subscription for a
  # given user.  The following parameter are passed to this method:
  #
  # 1) User Account
  #
  # This method will return a 'true' or 'false' indicating whether the
  # subscription was cancelled.
  ##########################################################################
  def cancel_subscription(account_user)

    subscription_cancelled = true

    if account_user.customer_id.present?
      begin

        Stripe.api_key = ENV['API_KEY']

        customer = Stripe::Customer.retrieve("#{account_user.customer_id}")

        customer.cancel_subscription()

        self.status = CANCELLED

        self.save

      rescue Stripe::StripeError => stripe_error
        logger_debugger(errors, stripe_error, customer_id, "[Subscription.cancel_subscription] error = #{stripe_error.message}")
        subscription_cancelled = false
      end
    end
    return subscription_cancelled
  end

  ##########################################################################
  # The destroy method cancels a Stripe subscription for a given user and
  # then deletes the customer.
  #
  # This method will return a 'true' or 'false' indicating whether the
  # subscription was canceled and the customer was deleted.
  ##########################################################################
  def destroy

    removed_customer = true

    if self.customer_id.present?
      begin

        cancel_subscription (self)
        Stripe.api_key = STRIPE[:api_key]
        customer = Stripe::Customer.retrieve("#{self.customer_id}")
        customer.delete

      rescue Stripe::StripeError => stripe_error
        logger_debugger(errors, stripe_error, customer_id, "[Subscription.destroy] error = #{stripe_error.message}")
        removed_customer = false
      end
    else
      removed_customer = false
    end

    return removed_customer
  end

  ##########################################################################
  # The sub_create function creates a new subscription by calling the
  # subscribe function.
  ##########################################################################
  def sub_create(current_user, stripe_pl_id, coupon)
    current_user.subscription = self
    self.subscribe(current_user.account, stripe_pl_id, coupon)
  end

  ## PROTECTED INSTANCE METHODS --------------------------------------------
  protected

  ##########################################################################
  # Utility method to dupate the subscription information from the Stripe
  # customer record.
  ##########################################################################
  def update_customer_subscription_info(customer, plan_id, coupon_code)
    customer_subscription = customer.update_subscription(
                              :plan => plan_id,
                              :coupon => coupon_code
    )
    self.cancel_at_period_end = customer_subscription.cancel_at_period_end
    self.current_period_start = customer_subscription.current_period_start
    self.current_period_end = customer_subscription.current_period_end
    self.trial_start = customer_subscription.trial_start
    self.trial_end = customer_subscription.trial_end
  end

  #########################################################################
  # Debug level logger
  #########################################################################
  def logger_debugger(errors, stripe_error, customer_id, description)
    logger.debug(description)
    errors[:customer_id] << stripe_error.message
  end
end
