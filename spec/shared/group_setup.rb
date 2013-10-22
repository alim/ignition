# Provide shared macros for testing user accounts
shared_context 'group_setup' do

  # Single group with multiple users
	let(:single_group_with_users) {
		5.times.each { FactoryGirl.create(:user_with_account) }
		@group = FactoryGirl.create(:group)
		@group.owner_id = User.first.id
		User.all.each {|user| @group.users << user}
	}
	
	# Multiple groups, but no users
	let(:multiple_groups) {
	  5.times.each { FactoryGirl.create(:group) }
	}
	
	# Multiple groups with overlapping user groups
	let(:multi_groups_multi_users) {
	  @group_count = 5
	  @groups = []
	  @group_count.times.each { @groups << FactoryGirl.create(:group) }

	  @groups.each do |group|
	    5.times.each {group.users << FactoryGirl.create(:user_with_account)}
	  end
	  @owner = FactoryGirl.create(:user)
	  @groups.each do |group| 
	    group.owner_id = @owner.id
	    group.users << @owner # Add the owner to the group
	    group.save
	  end
	}
end
