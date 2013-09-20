# Provide shared macros for testing user accounts
shared_context 'user_setup' do
	let(:create_users) {
		5.times.each { FactoryGirl.create(:user) }
	}
	
	let(:create_service_admins) {
	  5.times.each { FactoryGirl.create(:adminuser) }
	}
	
	let(:delete_users) {
		User.all.each do |user|
			user.destroy
		end
	}
	
	let(:signin_admin) {
		@user = FactoryGirl.create(:adminuser)
		sign_in @user
	}	
end
