########################################################################
# The Subcription model holds information about a subscription plan
# that will be created on the Stripe.com service. The model includes
# enhancements for timestamps and white space stripping.
######################################################################## 
class Subscription
  include Mongoid::Document
  include Mongoid::Timestamps

  # Add call to strip leading and trailing white spaces from all atributes
  strip_attributes  # See strip_attributes for more information
  
  ## CONSTANTS ---------------------------------------------------------
  
  # The PLAN_OPTIONS is a hash of Stripe.com plan ID's associated with
  # this service. Each hash enter includes a label and an id
  PLAN_OPTIONS = [
    {label: 'Bronze Plan', plan_id: 'ignition_bronze_plan'},
    {label: 'Silver Plan', plan_id: 'ignition_silver_plan'},
    {label: 'Gold Plan', plan_id: 'ignition_gold_plan'},
  ]
  
  # SUBSCRIPTION STATUS VALUES
  TRAILING = 'trialing'
  ACTIVE = 'active'
  PAST_DUE = 'past_due'
  CANCELED = 'canceled'
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
    when PLAN_OPTIONS[0][:plan_id]
      str = "Bronze Subscription Plan"
    when PLAN_OPTIONS[1][:plan_id]
      str = "Silver Subscription Plan"
    when PLAN_OPTIONS[2][:plan_id]
      str = "Gold Subscription Plan"
    else
      str = "Unknown Plan"
    end
    
    return str
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

 subscription_valid = true

if account_user.customer_id.present?

  begin

    Stripe.api_key = ENV['API_KEY']

    customer = Stripe::Customer.retrieve("#{account_user.customer_id}")

    self.stripe_plan_id = plan_id

    customer_subscription = customer.update_subscription(
                               :plan => plan_id,
#                              :plan => self.plan_str(),
                              :coupon => coupon_code
    )
    self.cancel_at_period_end = customer_subscription.cancel_at_period_end
    self.current_period_start = customer_subscription.current_period_start
    self.current_period_end = customer_subscription.current_period_end
    self.trial_start = customer_subscription.trial_start
    self.trial_end = customer_subscription.trial_end

    subscription_valid = self.save ? true : false

      rescue Stripe::StripError => stripe_error
      logger.debug("[Subscription.update_with_stripe] error = #{stripe_error.message}")
      errors[:customer_id] << stripe_error.message
      subscription_valid = false
      return nil
  end
 else 
  subscription_valid = false
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

    rescue Stripe::StripError => stripe_error
    logger.debug("[Subscription.cancel_with_stripe] error = #{stripe_error.message}")
    errors[:customer_id] << stripe_error.message
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
# subscription was cancelled and the customer was deleted.
##########################################################################
def destroy

   removed_customer = true

 if self.customer_id.present?

  begin

   cancel_subscription (self)
   Stripe.api_key = STRIPE[:api_key]
   customer = Stripe::Customer.retrieve("#{self.customer_id}")
   customer.delete

   rescue Stripe::StripError => stripe_error
   logger.debug("[Subscription.cancel_with_stripe] error = #{stripe_error.message}")
   errors[:customer_id] << stripe_error.message
   
   removed_customer = false
  end
 else
   removed_customer = false
 end

   return removed_customer
end

protected

  ######################################################################
  ######################################################################
def is_valid(params)

  subscription_valid = true

   if params[:cardholder_name].blank?
      errors[:cardholder_name] << "Cardholder name cannot be blank." 
      subscription_vaild = false
   end

   if params[:plan_id].blank?
      errors[:plan_id] << "Plan ID cannot be blank."
      subscription_valid = false
   end

   if params[:stripe_cc_token].blank?
      errors[:base] << "Could not get a valid response from Stripe.com"
      subscription_valid = false
   end

   return account_valid
end
end
