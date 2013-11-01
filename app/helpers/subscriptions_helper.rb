module SubscriptionsHelper

  ######################################################################
  # The subscription_plans is a view helper to list the available
  # subscriptions that are configured into the Subscription model
  # class. It is important that the Subsscription model class is 
  # synchronized with the online subscription plans on Stripe.com
  ######################################################################
  def subscription_plans
    plans = []
    Subscription::PLAN_OPTIONS.each do |plan|
      plans << [plan[:label], plan[:plan_id]]
    end
    return plans
  end
  
end
