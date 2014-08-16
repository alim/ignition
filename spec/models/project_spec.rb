require 'spec_helper'

describe Project do
  include_context 'project_setup'

  let(:a_project) { Project.where(:user_id.exists => true).first }

  before(:each) {
    projects_with_users
  }

  after(:each) {
    User.delete_all
    Project.delete_all
    Organization.delete_all
  }

  ## METHOD CHECKS -----------------------------------------------------
	describe "Should respond to all accessor methods" do
		it { should respond_to(:name) }
		it { should respond_to(:description) }
		it { should respond_to(:user_id) }
		it { should respond_to(:organization_id) }
	end

	## VALIDATION CHECKS -------------------------------------------------
	describe "Validation checks" do
	  describe "Valid tests" do
	    it "Should be valid with a user and NO organization" do
	      a_project.should be_valid
	    end
	  end

	  describe "Invalid tests" do
	    it "Should be invalid without a name" do
        project = a_project
	      project.name = nil
	      project.should_not be_valid
	    end

	    it "Should be invalid without a description" do
        project = a_project
	      project.description = nil
	      project.should_not be_valid
	    end

	    it "Should be invalid without a user_id" do
	      project = FactoryGirl.build(:project)
	      project.should_not be_valid
	    end

	    it "Project should be destroyed, if user is destroyed" do
        project = a_project
	      user = project.user
	      user.destroy
	      expect{
	        project.reload
	      }.to raise_error(Mongoid::Errors::DocumentNotFound)
	    end
	  end

    describe "Organizational concern tests" do

      describe "scope tests" do
        let(:new_user) { FactoryGirl.create(:user) }
        let(:other_project) { FactoryGirl.create(:project, user: new_user) }
        before(:each){
          other_project
        }

        it "should find projects with matching user, but no organization" do
          projects = Project.in_organization(a_project.user)
          projects.each do |project|
            project.user_id.should == a_project.user.id
            project.organization.should be_nil
          end

          projects.count.should <  Project.count
        end

        it "should find a subset of the projects" do
          projects = Project.in_organization(a_project.user)
          projects.count.should > 0
          projects.count.should <  Project.count
        end

        it "should find all projects part of the user's organization" do
          # Create projects with different owners and
          5.times { other_project }
          owner = User.last
          org = FactoryGirl.create(:organization, owner: owner)

          # Find projects not matching owner
          projects = Project.ne(user_id: owner.id)
          projects.count.should > 0

          # Add projects to organization
          org.projects << projects

          # user_projects = Project.where(user_id: @project.user_id)
          found_projects = Project.in_organization(projects.last.user)

          found_projects.count.should > 0

          found_projects.each do |project|
            project.organization.id.should == org.id
            project.organization.id.should_not be_nil
            project.user.should_not eq owner
          end
        end
      end

      describe "relate_to_organization tests" do
        let(:org_owner){ FactoryGirl.create(:user) }
        let(:org){ FactoryGirl.create(:organization, owner: org_owner) }
        let(:a_user){ FactoryGirl.create(:user) }

        it "should not relate project to an organization if user doesn't belong to one" do
          a_project.organization.should be_nil
          a_project.relate_to_organization
          a_project.organization.should be_nil
        end

        it "should relate project to a user's organization" do
          org.users << a_user
          a_project.user = a_user
          a_project.organization.should be_nil

          a_project.relate_to_organization
          a_project.organization.should == org
        end

      end
    end

	end
end
