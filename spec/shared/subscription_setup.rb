# Provide shared macros for testing user accounts
shared_context 'subscription_setup' do
	let(:create_subscriptions) {
		5.times.each { FactoryGirl.create(:subscription) }
	}
end
