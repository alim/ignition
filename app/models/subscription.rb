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
  field :ended_at, type: DateTime
  field :trial_start, type: DateTime
  field :trial_end, type: DateTime
  
  ## Non-database attribute for storing a coupon code when subscribing
  attr_accessor :coupon_code
  
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
end
