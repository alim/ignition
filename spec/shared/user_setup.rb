# Provide shared macros for testing user accounts
shared_context 'user_setup' do
	let(:create_users) {
		5.times.each { FactoryGirl.create(:user) }
	}
	
	let(:create_service_admins) {
	  5.times.each { FactoryGirl.create(:adminuser) }
	}
	
	let(:create_users_with_account) {
	  5.times.each { FactoryGirl.create(:user_with_account) }
	}
	
	let(:delete_users) {
		User.all.each do |user|
			user.destroy
		end
	}
	
	let(:signin_admin) {
		@signed_in_user = FactoryGirl.create(:adminuser)
		sign_in @signed_in_user
	}
	
  let(:signin_customer) {
		@signed_in_user = FactoryGirl.create(:user)
		sign_in @signed_in_user
	}
	
	# Logout of current user and login as an administrator
  let(:login_admin) {
    sign_out @signed_in_user
    signin_admin
    subject.current_user.should_not be_nil
  }	
end
