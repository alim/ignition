class Subscription
  include Mongoid::Document
  field :plan_id, type: Integer
  field :stripe_id, type: String
  field :cancel_at_period_end, type: String
  field :stripe_customer_id, type: String
  field :quantity, type: Integer
  field :sub_start, type: Time
  field :sub_end, type: Time
  field :status, type: String
  field :canceled_at, type: Time
  field :current_period_start, type: Time
  field :current_period_end, type: Time
  field :ended_at, type: Time
  field :trial_start, type: Time
  field :trial_end, type: Time
end
