# Provide shared macros for testing user accounts
shared_context 'group_setup' do

  # Single group with multiple users
	let(:single_group_with_users) {
		5.times.each { FactoryGirl.create(:user_with_account) }
		@group = FactoryGirl.create(:group)
		@group.owner_id = User.first.id
		User.all.each {|user| @group.users << user}
	}
	
	# Multiple groups, but now users
	let(:multiple_groups) {
	  5.times.each { FactoryGirl.create(:group) }
	}
	
	# Multiple groups with overlapping user groups
	let(:multi_groups_multi_users) {
	  5.times.each { FactoryGirl.create(:group) }
	  @groups = Group.all
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
