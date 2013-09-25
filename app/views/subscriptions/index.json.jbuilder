json.array!(@subscriptions) do |subscription|
  json.extract! subscription, :plan_id, :stripe_id, :cancel_at_period_end, :stripe_customer_id, :quantity, :sub_start, :sub_end, :status, :canceled_at, :current_period_start, :current_period_end, :ended_at, :trial_start, :trial_end
  json.url subscription_url(subscription, format: :json)
end
