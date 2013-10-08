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
end
