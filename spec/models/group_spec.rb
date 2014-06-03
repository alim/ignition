require 'spec_helper'

describe Group do
  include_context 'user_setup'
  include_context 'group_setup'

  # SETUP --------------------------------------------------------------
  let(:find_one_group) {
    multiple_groups
    @one_group = Group.first
  }

  before(:each) {
    find_one_group
  }

  after(:each) {
    User.destroy_all
    Group.destroy_all
  }

  # ATTRIBUTE TESTS ----------------------------------------------------
  describe "Attribute tests" do
    it { should respond_to(:name) }
		it { should respond_to(:description) }
		it { should respond_to(:owner_id) }
  end

  # VALIDATION TESTS ---------------------------------------------------
  describe "Validation tests" do
    it "Should not be valid without a name" do
      @one_group.name = nil
      @one_group.should_not be_valid
    end

    it "Should not be valid without a description" do
      @one_group.description = nil
      @one_group.should_not be_valid
    end
  end

  # MEMBERSHIP TESTS ---------------------------------------------------
  describe "Group membership email list tests" do
    let(:email_list) {
      "abc@example.com\ndef@example.com\tghi@example.com jkl@example.com"
    }

    let(:invalid_email_list) {
      "abc\ndef@example\t@example.com jkl@.com"
    }

    it "Should store a list of white space delimited email addresses" do
      @one_group.members = email_list
      @one_group.should be_valid
      @one_group.members.should eq(email_list)
    end

    it "Should not be valid, with invalid email list" do
      @one_group.members = invalid_email_list
      @one_group.should_not be_valid
      @one_group.members.should eq(invalid_email_list)
    end

    it "Should log errors for each invalid email address" do
      @one_group.members = invalid_email_list
      @one_group.should_not be_valid
      email = invalid_email_list.split
      i = 0
      @one_group.errors.full_messages.each do |message|
        message.should match(/#{email[i]}/)
        i += 1
      end
      i.should eq(email.count)
    end
  end

  # GROUP RELATIONSHIP TESTS -------------------------------------------
  describe "Group relationship testing" do
    describe "Single group with multiple users" do
      before(:each) {
        Group.destroy_all # Clear out all existing groups
        single_group_with_users
        @group = Group.first
      }

      it "Should allow access to each user email" do
        @group.users.count.should eq(5)
        @group.users.each { |user| user.email.should be_present }
      end

      it "Should allow access to each user first_name" do
        @group.users.count.should eq(5)
        @group.users.each { |user| user.first_name.should be_present }
      end

      it "Should allow access to each user last_name" do
        @group.users.count.should eq(5)
        @group.users.each { |user| user.last_name.should be_present }
      end

      it "Should allow access to the group name from each user" do
        User.all.each do |user|
          user.groups.each do |group|
            group.name.should be_present
            group.id.should eq(@group.id)
          end
        end
      end

      it "Should allow access to the group description from each user" do
        User.all.each do |user|
          user.groups.each do |group|
            group.description.should be_present
            group.id.should eq(@group.id)
          end
        end
      end
    end # Single group with multiple users

    describe "Multiple groups with multiple users" do
      before(:each){
        Group.destroy_all
        multi_groups_multi_users
      }

      it "Should be able to have an user as a member across all groups" do
        Group.all.each do |group|
          group.users.find(@owner.id).should be_present
        end
      end

      it "Should find users for each group" do
        Group.all.each { |group| group.users.count.should_not eq(0) }
      end

      it "Should be able access user email address for each group member" do
        Group.all.each do |group|
          group.users.each {|user| user.email.should be_present}
        end
      end

      it "Should be able access user first_name for each group member" do
        Group.all.each do |group|
          group.users.each {|user| user.first_name.should be_present}
        end
      end

      it "Should be able access user last_name for each group member" do
        Group.all.each do |group|
          group.users.each {|user| user.last_name.should be_present}
        end
      end

      it "Should be able access user phone for each group member" do
        Group.all.each do |group|
          group.users.each {|user| user.phone.should be_present}
        end
      end
    end
  end # Group relationships

  # SCOPE TESTS --------------------------------------------------------
  describe "Scope tests" do
    before(:each) {
      multi_groups_multi_users
      multiple_groups
    }

    describe "owned_groups scope" do
      it "should find the correct number of groups" do
        groups = Group.owned_groups(@owner)
        groups.count.should eq(@group_count)
      end

      it "should find only groups associated with a given user" do
        groups = Group.owned_groups(@owner)
        groups.each do |group|
          group.owner_id.should eq(@owner.id)
        end
      end

      it "should not find any records for non-owner" do
        user = User.where(:id.ne => @owner.id).first
        groups = Group.owned_groups(user)
        groups.should be_empty
      end
    end
  end

  # GROUP USER TESTS --------------------------------------------------

  describe "lookup_users tests" do
    let(:group) { Group.last }
    let(:user_list) { group.users.pluck(:email).join(' ') }
    before(:each) {
      multi_groups_multi_users
    }

    it "should return a hash of all matching user emails" do
      group.members = user_list
      group.should be_valid
      users = group.lookup_users
      users.should_not be_empty
      users.keys.join(' ').should == user_list
    end


    it "should return a hash of all User classes" do
      group.members = user_list
      group.should be_valid
      users = group.lookup_users
      users.should_not be_empty
      users.values.each {|u| u.class == User }
    end

    it "should return an empty hash if no members present" do
      group.members = nil
      group.should be_valid
      group.lookup_users.should be_empty
    end
  end

  describe "create and notify tests" do
    let(:new_members) { "roger_rabbit@warner.com   jessica_rabbit@warner.com" }
    before(:each) {
      ActionMailer::Base.deliveries.clear
      single_group_with_users
    }

    after(:each) { ActionMailer::Base.deliveries.clear }

    it "should users to the group" do
      @group.members = new_members
      @group.create_notify
      @group.users.count == 7

      new_members.split {|e| User.where(email: e).should_not be_empty }
    end

    it "should create an email for each new user" do
      @group.members = new_members
      @group.create_notify
      ActionMailer::Base.deliveries.count.should == 2
    end

    it "should create an email messages with the right fields" do
      @group.members = new_members
      @group.create_notify

      ActionMailer::Base.deliveries.each do |d|
        new_members.split.should include(d.to[0])
        d.from[0].should match(/no-reply/)
        d.subject.should match(/has added you to their group.$/)
      end
    end

    it "should not notify existing users" do
      current_users = @group.users.pluck(:email)
      @group.members = new_members
      @group.create_notify

      ActionMailer::Base.deliveries.each do |d|
        current_users.split.should_not include(d.to[0])
      end
    end
  end

  describe "invite user tests" do
    before(:each) {
      ActionMailer::Base.deliveries.clear
      single_group_with_users
    }
    after(:each) { ActionMailer::Base.deliveries.clear }

    it "should create an email for the invited user" do
      @group.invite_member(@group.users.last)
      ActionMailer::Base.deliveries.count.should == 1
    end

    it "should address it to the write person" do
      @group.invite_member(@group.users.last)
      ActionMailer::Base.deliveries.count.should == 1
      ActionMailer::Base.deliveries.first.to[0].should == @group.users.last.email
    end

    it "should have a password set" do
      @group.invite_member(@group.users.last)
      ActionMailer::Base.deliveries.count.should == 1
      ActionMailer::Base.deliveries.first.encoded.should match(/password:/)
    end
  end
end
