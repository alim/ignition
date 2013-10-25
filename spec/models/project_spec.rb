require 'spec_helper'

describe Project do
  include_context 'project_setup'
  
  let(:find_a_project) {
    @project = Project.where(:user_id.exists => true).first
  }
  
  before(:each) {
    projects_with_users
    find_a_project
  }
  
  after(:each) {
    User.delete_all
    Project.delete_all
    Group.delete_all
  }

  ## METHOD CHECKS -----------------------------------------------------
	describe "Should respond to all accessor methods" do
		it { should respond_to(:name) }
		it { should respond_to(:description) }
		it { should respond_to(:user_id) }
		it { should respond_to(:group_id) }
	end
	
	## VALIDATION CHECKS -------------------------------------------------
	describe "Validation checks" do
	  describe "Valid tests" do
	    it "Should be valid with a user and NO group" do
	      @project.should be_valid
	    end
	  end
	  
	  describe "Invalid tests" do
	    it "Should be invalid without a name" do
	      @project.name = nil
	      @project.should_not be_valid
	    end
	    
	    it "Should be invalid without a description" do
	      @project.description = nil
	      @project.should_not be_valid
	    end
	    
	    it "Should be invalid without a user_id" do
	      project = FactoryGirl.build(:project)
	      project.should_not be_valid
	    end
	    
	    it "Project should be destroyed, if user is destroyed" do
	      user = @project.user
	      user.destroy
	      expect{
	        @project.reload
	      }.to raise_error(Mongoid::Errors::DocumentNotFound)
	    end
	  end
	end
end
