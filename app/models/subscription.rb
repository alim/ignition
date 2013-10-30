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
  
  # CONSTANTS ----------------------------------------------------------
  
  # The PLAN_OPTIONS is a hash of Stripe.com plan ID's associated with
  # this service
  PLAN_OPTIONS = {
    bronze: 'plan_bronze',
    silver: 'plan_silver',
    gold: 'plan_gold',
    platinum: 'plan_paltinum',
  }
  
  
  # ATTRIBUTES ---------------------------------------------------------
  
  field :plan_id, type: String
  field :stripe_id, type: String
  field :cancel_at_period_end, type: Boolean
  field :stripe_customer_id, type: String
  field :quantity, type: Integer
  field :sub_start, type: DateTime
  field :sub_end, type: DateTime
  field :status, type: String
  field :canceled_at, type: DateTime
  field :current_period_start, type: DateTime
  field :current_period_end, type: DateTime
  field :ended_at, type: DateTime
  field :trial_start, type: DateTime
  field :trial_end, type: DateTime
  
  
  # VALIDATIONS --------------------------------------------------------
  
  validates_presence_of :plan_id
  validates_presence_of :stripe_id
  validates_presence_of :stripe_customer_id
  validates_presence_of :quantity
  validates_presence_of :sub_start
  validates_presence_of :sub_end
  validates_presence_of :status
  validates_presence_of :user_id

  
  # RELATIONSHIPS ------------------------------------------------------
  
  belongs_to :user
end
