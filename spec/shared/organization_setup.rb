# Provide shared macros for testing user accounts
shared_context 'organization_setup' do

  # Single organization with multiple users
	let(:single_organization_with_users) {
		5.times.each { FactoryGirl.create(:user_with_account) }
		@owner = User.first
		@organization = FactoryGirl.create(:organization, owner: @owner)
		User.all.each {|user| @organization.users << user}
	}

	# Multiple organizations, but no users
	let(:multiple_organizations) {
	  5.times.each { FactoryGirl.create(:organization, owner:  FactoryGirl.create(:user_with_account)) }
	}

end
