require 'spec_helper'

describe Organization do
  include_context 'user_setup'
  include_context 'organization_setup'
  include_context 'project_setup'

  # SETUP --------------------------------------------------------------
  let(:one_organization) {
    multiple_organizations
    Organization.last
  }

  after(:each) {
    User.destroy_all
    Organization.destroy_all
  }

  # ATTRIBUTE TESTS ----------------------------------------------------
  describe "Attribute tests" do
    it { should respond_to(:name) }
		it { should respond_to(:description) }
		it { should respond_to(:owner) }
  end

  # VALIDATION TESTS ---------------------------------------------------
  describe "Validation tests" do
    it "Should be valid with all fields" do
      one_organization.should be_valid
    end

    it "Should not be valid without a name" do
      one_organization.name = nil
      one_organization.should_not be_valid
    end

    it "Should not be valid without a description" do
      one_organization.description = nil
      one_organization.should_not be_valid
    end

    it "Should not be valid without an owner" do
      one_organization.owner = nil
      one_organization.should_not be_valid
    end
  end

  # MEMBERSHIP TESTS ---------------------------------------------------
  describe "Organization membership email list tests" do
    let(:email_list) {
      "abc@example.com\ndef@example.com\tghi@example.com jkl@example.com"
    }

    let(:invalid_email_list) {
      "abc\ndef@example\t@example.com jkl@.com"
    }

    it "Should store a list of white space delimited email addresses" do
      one_organization.members = email_list
      one_organization.should be_valid
      one_organization.members.should eq(email_list)
    end

    it "Should not be valid, with invalid email list" do
      one_organization.members = invalid_email_list
      one_organization.should_not be_valid
      one_organization.members.should eq(invalid_email_list)
    end

    it "Should log errors for each invalid email address" do
      one_organization.members = invalid_email_list
      one_organization.should_not be_valid
      email = invalid_email_list.split
      i = 0
      one_organization.errors.full_messages.each do |message|
        message.should match(/#{email[i]}/)
        i += 1
      end
      i.should eq(email.count)
    end
  end

  # RELATIONSHIP TESTS -------------------------------------------
  describe "Organization relationship testing" do
    describe "Single organization with multiple users" do
      before(:each) {
        single_organization_with_users
        @organization = Organization.first
      }

      it "Should allow access to each user email" do
        @organization.users.count.should eq(5)
        @organization.users.each { |user| user.email.should be_present }
      end

      it "Should allow access to each user first_name" do
        @organization.users.count.should eq(5)
        @organization.users.each { |user| user.first_name.should be_present }
      end

      it "Should allow access to each user last_name" do
        @organization.users.count.should eq(5)
        @organization.users.each { |user| user.last_name.should be_present }
      end

      it "Should allow access to the organization name from each user" do
        User.all.each do |user|
          user.organization.name.should be_present
          user.organization.id.should eq(@organization.id)
        end
      end

      it "Should allow access to the organization description from each user" do
        User.all.each do |user|
          user.organization.description.should be_present
          user.organization.id.should eq(@organization.id)
        end
      end
    end # Single organization with multiple users

  end # Organization relationships

  # ORGANIZATION USER TESTS -------------------------------------------

  describe "lookup_users tests" do
    let(:organization) { Organization.last }
    let(:user_list) { organization.users.pluck(:email).join(' ') }
    before(:each) {
      single_organization_with_users
    }

    it "should return a hash of all matching user emails" do
      organization.members = user_list
      organization.should be_valid
      users = organization.lookup_users
      users.should_not be_empty
      users.keys.join(' ').should == user_list
    end


    it "should return a hash of all User classes" do
      organization.members = user_list
      organization.should be_valid
      users = organization.lookup_users
      users.should_not be_empty
      users.values.each {|u| u.class == User }
    end

    it "should return an empty hash if no members present" do
      organization.members = nil
      organization.should be_valid
      organization.lookup_users.should be_empty
    end
  end

  describe "create and notify tests" do
    let(:new_members) { "roger_rabbit@warner.com   jessica_rabbit@warner.com" }
    before(:each) {
      ActionMailer::Base.deliveries.clear
      single_organization_with_users
    }

    after(:each) { ActionMailer::Base.deliveries.clear }

    it "should users to the organization" do
      @organization.members = new_members
      @organization.create_notify
      @organization.users.count == 7

      new_members.split {|e| User.where(email: e).should_not be_empty }
    end

    it "should create an email for each new user" do
      @organization.members = new_members
      @organization.create_notify
      ActionMailer::Base.deliveries.count.should == 2
    end

    it "should create an email messages with the right fields" do
      @organization.members = new_members
      @organization.create_notify

      ActionMailer::Base.deliveries.each do |d|
        new_members.split.should include(d.to[0])
        d.from[0].should match(/no-reply/)
        d.subject.should match(/has added you to their organization.$/)
      end
    end

    it "should not notify existing users" do
      current_users = @organization.users.pluck(:email)
      @organization.members = new_members
      @organization.create_notify

      ActionMailer::Base.deliveries.each do |d|
        current_users.split.should_not include(d.to[0])
      end
    end
  end

  describe "invite user tests" do
    before(:each) {
      ActionMailer::Base.deliveries.clear
      single_organization_with_users
    }
    after(:each) { ActionMailer::Base.deliveries.clear }

    it "should create an email for the invited user" do
      @organization.invite_member(@organization.users.last)
      ActionMailer::Base.deliveries.count.should == 1
    end

    it "should address it to the write person" do
      @organization.invite_member(@organization.users.last)
      ActionMailer::Base.deliveries.count.should == 1
      ActionMailer::Base.deliveries.first.to[0].should == @organization.users.last.email
    end

    it "should have a password set" do
      @organization.invite_member(@organization.users.last)
      ActionMailer::Base.deliveries.count.should == 1
      ActionMailer::Base.deliveries.first.encoded.should match(/password:/)
    end
  end

  # RELATE CLASSES ----------------------------------------------------
  describe "#relate_classes" do
    before(:each) {
      single_organization_with_users
      10.times.each { FactoryGirl.create(:project, user: @owner)}
    }

    it "should set the organization of managed projects" do
      Project.all.each do |project|
        project.organization.should be_nil
      end
      @organization.relate_classes
      @organization.projects.count.should > 0
      Project.all.each { |project| project.organization.should == @organization }
    end

    it "should not relate projects not created by organization owner" do
      user = FactoryGirl.create(:user)

      Project.all.each do |project|
        project.user = user
        project.save
      end

      @organization.relate_classes
      @organization.projects.count.should == 0
    end

  end

  ## MANAGE CLASSES ---------------------------------------------------

  describe "#managed_classes" do
    before(:each) {
      single_organization_with_users
      10.times.each { FactoryGirl.create(:project, user: @owner)}
    }

    it "should find all instances of a related class" do
      Project.all.each do |project|
        project.organization = @organization
        project.save
      end

      mclasses = @organization.managed_classes
      mclasses[:project].each do |project|
        project.organization.should == @organization
      end
    end

  end

  ## UNRELATE CLASSES -------------------------------------------------

  describe "#unrelate_classes" do
    let(:setup_projects) {
      Project.all.each do |project|
        project.organization.should be_nil
      end
    }
    before(:each) {
      projects_with_users
      single_organization_with_users
    }

    it "should un-relate project classes" do
      setup_projects
      @organization.relate_classes
      @organization.projects.count.should > 0
      Project.all.each { |project| project.organization.should == @organization }
      @organization.unrelate_classes
      @organization.projects.count.should == 0
      Project.count.should > 0
    end
  end

  ## CREATE WITH OWNER ------------------------------------------------

  describe "#create_with_owner" do
    let(:owner){ FactoryGirl.create(:user) }

    let(:name) {"Sample Organization"}
    let(:desc) {"The sample organization for testing"}
    let(:members) {"one@example.com\ntwo@example.com\nthree@example.com\n"}

    let(:org_params) do
      {
        name: name,
        description: desc,
        members: members
      }
    end

    it "should create a new Organization" do
      expect {
        Organization.create_with_owner(org_params, owner).save
      }.to change(Organization, :count).by(1)
    end

    it "should relate the organization to the correct user" do
      org = Organization.create_with_owner(org_params, owner)
      org.owner.should == owner
      owner.organization.should == org
    end
  end
end
