# Provide shared macros for testing user accounts
shared_context 'project_setup' do

	let(:projects) {
	  5.times.each { FactoryGirl.create(:project) }
	}

  let(:projects_with_users) {
    user = FactoryGirl.create(:user)
    user.save
    5.times.each do
      project = FactoryGirl.create(:project, user: user)
    end
  }

end
