require 'spec_helper'

describe GroupsController do

  include_context 'user_setup'
  include_context 'group_setup'

  # TEST SETUP ---------------------------------------------------------
  let(:find_one_user) {
    @customer = User.where(role: User::CUSTOMER).where(:account.exists => true).first
  }
  
  let(:find_one_group) {
    @group = Group.where(:owner_id.exists => true).first
  }
  
  before(:each) {
		multi_groups_multi_users
		find_one_user
		find_one_group
		signin_customer
		subject.current_user.should_not be_nil
	}
	
	after(:each) {
		delete_users
		Group.delete_all
  }
  
  # INDEX ACTION TESTS -------------------------------------------------

  describe "GET index" do
    describe "Valid examples" do
      it "Should return success" do
        get :index
        response.should be_success
      end
      
      it "Should render index template" do
        get :index
        response.should render_template :index
      end
      
      it "Should return the complete list of groups" do
        ids = @groups.pluck(:id).sort
        get :index
        assigns(:groups).pluck(:id).sort.should eq(ids)
      end
      
      it "should set the menu active flag for admin menu" do
				get :index
				assigns(:groups_active).should eq("class=active")
			end      
    end # Valid examples
    
    describe "Invalid examples" do
      it "Should redirect to sign in, if not signed in" do
  	    sign_out @signed_in_user
  	    get :index
  	    response.should redirect_to new_user_session_url
  	  end
  	  
  	  it "Should still return success, if no groups present" do
  	    Group.delete_all
  	    get :index
  	    response.should be_success
  	    assigns(:groups).count.should eq(0)
  	  end
    end
  end


  # SHOW ACTION TESTS --------------------------------------------------

  describe "GET show" do
    let(:show_params) {
      { id: @group.id }
    }
    
    describe "Valid examples" do
    
      it "Should return with success" do
        get :show, show_params
        response.should be_success
      end
      
      it "Should use the show template" do
        get :show, show_params
        response.should render_template :show
      end
      
      it "Should find matching user record" do
        get :show, show_params
        assigns(:group).id.should eq(@group.id)
      end
      
      it "Should find matching owner email" do
        owner = User.find(@group.owner_id)
        get :show, show_params
        assigns(:owner_email).should eq(owner.email)
      end      
      
      it "Should find all users for the group" do
        uids = @group.users.all.pluck(:id).sort
        get :show, show_params
        assigns(:group).users.pluck(:id).sort.should eq(uids)
      end

      it "should set the menu active flag for admin menu" do
				get :index
				assigns(:groups_active).should eq("class=active")
			end       
    end # Valid examples
    
    describe "Invalid examples" do 
       it "Should not succeed, if not logged in" do
        sign_out @signed_in_user
        get :show, show_params
        response.should_not be_success
      end
      
      it "Should redirect, if not logged in" do
        sign_out @signed_in_user
        get :show, show_params
        response.should redirect_to new_user_session_url
      end
      
      it "Should redirect to #index, if record not found" do
        get :show, {id: '99999'}
        response.should redirect_to groups_url
      end
      
      it "Should flash an alert message, if record not found" do
        get :show, {id: '99999'}
        flash[:alert].should match(/^Unable to find group information for group #/)
      end 
      
      it "Should flash an alert if we cannot find a group owner" do
        @group.owner_id = '9999'
        @group.save
        
        get :show, show_params
        flash[:alert].should match(/Unable to find User member information for group/)
      end
    end
  end

  # NEW TESTS ----------------------------------------------------------
  describe "GET new" do
    describe "Valid tests" do
      it "Should return success" do
        get :new
        response.should be_success
      end

      it "Should use the new template" do
        get :new
        response.should render_template :new
      end
    
      it "Should set a new group record" do
        get :new
        assigns(:group).should be_present
      end
      
      it "Should set a resources list" do
        get :new
        assigns(:resources).should be_present
        assigns(:resources).class.should eq(Array)
      end      
    
      it "should set the menu active flag for admin menu" do
				get :new
				assigns(:groups_active).should eq("class=active")
			end 
		end # Valid tests
		
		describe "Invalid tests" do
		  it "Should redirect, if not logged in" do
        sign_out @signed_in_user
        get :new
        response.should redirect_to new_user_session_url
      end
		end
		
  end

  # EDIT ACTION TESTS --------------------------------------------------
  
  describe "GET edit" do
    let(:edit_params) { {id: @group.id} }
    
    describe "Valid tests" do
      it "Should return success" do
        get :edit, edit_params
        response.should be_success
      end

      it "Should use the edit template" do
        get :edit, edit_params
        response.should render_template :edit
      end
    
      it "Should find the group record" do
        get :edit, edit_params
        assigns(:group).id.should eq(@group.id)
      end
      
      it "Should set a resources list" do
        get :edit, edit_params
        assigns(:resources).should be_present
        assigns(:resources).class.should eq(Array)
      end      
    
      it "should set the menu active flag for admin menu" do
				get :edit, edit_params
				assigns(:groups_active).should eq("class=active")
			end 
		end # Valid tests
		
		describe "Invalid tests" do
		  it "Should redirect, if not logged in" do
        sign_out @signed_in_user
        get :edit, edit_params
        response.should redirect_to new_user_session_url
      end
      
      it "Should redirect to groups_url for invalid group id" do
        get :edit, {id: '090909'}
        response.should redirect_to groups_url
      end

      it "Should flash alert message for invalid group id" do
        get :edit, {id: '090909'}
        flash[:alert].should match(/We could not find the requested group/)
      end      
		end
  end

  # CREATE ACTION TESTS ------------------------------------------------
  describe "POST create" do
    let(:name) {"Sample Group"}
    let(:desc) {"The sample group for testing"}
    let(:members) {"one@example.com\ntwo@example.com\nthree@example.com\n"}
    
    let(:valid_group_params){
      {group: {
			  name: name,
			  description: desc,
			  members: members
		  }}
    }

    describe "Valid create examples" do
      it "Should return success with valid group fields" do
        post :create, valid_group_params
        response.should redirect_to group_url(assigns(:group))
        flash[:notice].should match(/Group was successfully created./)
      end
      
      it "Should update group with name" do
        post :create, valid_group_params
        assigns(:group).name.should eq(name)
      end
      
      it "Should update group with description" do
        post :create, valid_group_params
        assigns(:group).description.should eq(desc)
      end
      
      it "Should generate a member list of email addresses" do
        post :create, valid_group_params
        assigns(:members).should be_present
      end
      
      it "Should create new user records for each email address" do
        post :create, valid_group_params
        members.split.each do |email|
          assigns(:group).users.where(email: email).first.should be_present
        end
      end
      
      it "Should notify each user of their account" do
        post :create, valid_group_params
        ActionMailer::Base.deliveries.each do |delivery|
          members.should match(/#{delivery.to}/)
        end
      end
      
    end # Valid create examples
    
    describe "Invalid create examples" do
    
      it "Should redirect to sign_in, if not logged in" do
        sign_out @signed_in_user
        post :create, valid_group_params
        response.should redirect_to new_user_session_url
      end
         
      it "Should render the new template, if account could not save" do

        # Setup a method stub for the Group method save
        # to return nil, which indicates a failure to save the account
        Group.any_instance.stub(:save).and_return(nil)
        
        post :create, valid_group_params
        response.should render_template :new
      end
           
      it "Should generate error message with illegal email address" do
        params = valid_group_params
        params[:group][:members] = "abc\ndef@\n@example.com\nabc@.com\ndef@example"
        post :create, params
        assigns(:verrors).each {|error| error.should match(/Members invalid email address/)}
      end
      
      it "Should render the new template with illegal email address" do
        params = valid_group_params
        params[:group][:members] = "abc\ndef@\n@example.com\nabc@.com\ndef@example"
        post :create, params
        response.should render_template :new
      end
        
    end # Invalid create examples
  end

  # UPDATE ACTION TESTS ------------------------------------------------

  describe "PUT update" do
    let(:new_name) {"New Group Name"}
    let(:new_desc) {"New group description"}
    let(:new_members) {"123@example.com\n456@example.com\n789@example.com\n"}
    
    let(:update_params){
      { id: @group.id,
        group:
        {
          name: new_name,
          description: new_desc,
          members: new_members
        }
      }
    }
    
    describe "Valid update examples" do
      it "Should redirect to Group#show path" do
        put :update, update_params   
        response.should redirect_to group_url(@group)
      end

      it "Should find the correct group record" do
        put :update, update_params
        assigns(:group).id.should eq(@group.id)
      end     
         
      it "Should update group with description" do
        put :update, update_params
        assigns(:group).description.should eq(new_desc)
      end
      
      it "Should generate a member list of email addresses" do
        put :update, update_params
        assigns(:members).should be_present
      end
      
      it "Should create new user records for each email address" do
        put :update, update_params
        new_members.split.each do |email|
          assigns(:group).users.where(email: email).first.should be_present
        end
      end
      
      it "Should notify each user of their account" do
        put :update, update_params
        ActionMailer::Base.deliveries.each do |delivery|
          new_members.should match(/#{delivery.to}/)
        end
      end      
        
    end # Valid update examples
    
    describe "Invalid update examples" do
      it "Should redirect to sign_in, if not logged in" do
        sign_out @signed_in_user
        put :update, update_params
        response.should redirect_to new_user_session_url
      end
      
      it "Should redirect to users#index, if user not found" do
        params = update_params
        params[:id] = '99999'
        put :update, params
        response.should redirect_to groups_url
      end   
      
      it "Should flash error message, if group not found" do
        params = update_params
        params[:id] = '99999'
        put :update, params
        flash[:alert].should match(/We could not find the requested group to update/)
      end
      
      it "Should render the edit template, if group could not save" do

        # Setup a method stub for the group method save
        # to return nil, which indicates a failure to save the account
        Group.any_instance.stub(:update_attributes).and_return(nil)
        
        post :update, update_params
        response.should render_template :edit
      end
           
      it "Should generate error message with illegal email address" do
        params = update_params
        params[:group][:members] = "abc\ndef@\n@example.com\nabc@.com\ndef@example"
        post :update, params
        assigns(:verrors).each {|error| error.should match(/Members invalid email address/)}
      end
      
      it "Should render the new template with illegal email address" do
        params = update_params
        params[:group][:members] = "abc\ndef@\n@example.com\nabc@.com\ndef@example"
        post :update, params
        response.should render_template :edit
      end
          
    end # Invalid update examples
  end

  # DELETE ACTION CREATE -----------------------------------------------

  describe "DELETE destroy" do
    let(:destroy_params) {
      {
        id: @group.id
      }
    }
    
    describe "Valid examples" do
      it "Should redirect to #index" do
        delete :destroy, destroy_params
        response.should redirect_to groups_url
      end

      it "Should display a success message" do
        delete :destroy, destroy_params
        flash[:notice].should match(/Group was successfully deleted./)
      end
      
      it "Should delete account record" do
        expect{
          delete :destroy, destroy_params
        }.to change(Group, :count).by(-1)
      end
    end # Valid examples
    
    describe "Invalid examples" do
      it "Should redirect to sign_in, if not logged in" do
        sign_out @signed_in_user
        delete :destroy, destroy_params
        response.should redirect_to new_user_session_url
      end
          
      it "Should redirect to users#index, if no group record found" do
        params = destroy_params
        params[:id] = '00999'
        delete :destroy, params
        response.should redirect_to groups_url
      end
      
      it "Should flash an error message, if no group record found" do
        params = destroy_params
        params[:id] = '00999'
        delete :destroy, params
        flash[:alert].should match(/Could not find requeted group to delete./)      
      end          
    end # Invalid examples
  end

  # NOTIFY ACTION TESTS ------------------------------------------------
  
  describe "Notify tests" do
    let(:notify_params) {
      {
        id: @group.id,
        uid: @group.users.last.id
      }
    }
    
    describe "Valid examples" do
      it "Should redirect to group_url" do
        put :notify, notify_params      
        response.should redirect_to group_url(assigns(:group))
      end 
      
      it "Should find the matching group" do
        put :notify, notify_params
        assigns(:group).id.should eq(@group.id)
      end
      
      it "Should find the matching member user" do
        put :notify, notify_params
        assigns(:user).id.should eq(@group.users.last.id)
      end
      
      it "Should notify each user of their account" do
        user = @group.users.last
        put :notify, notify_params
        user.email.should match (/#{ActionMailer::Base.deliveries.last.to}/)
      end   
    end
    
    describe "Invalid examples" do
      it "Should redirect to sign_in, if not logged in" do
        sign_out @signed_in_user
        put :notify, notify_params
        response.should redirect_to new_user_session_url
      end
         
      it "Should redirect to groups_url if bad group id" do
        notify_params[:id] = '99999'
        put :notify, notify_params
        response.should redirect_to groups_url
      end

      it "Should flash an alert message if bad group id" do
        notify_params[:id] = '99999'
        put :notify, notify_params
        flash[:alert].should match(/We could not find the requested group/)
      end

      it "Should redirect to groups_url if bad user id" do
        notify_params[:uid] = '99999'
        put :notify, notify_params
        response.should redirect_to groups_url
      end

      it "Should flash an alert message if bad user id" do
        notify_params[:uid] = '99999'
        put :notify, notify_params
        flash[:alert].should match(/We could not find the requested group member./)
      end
      
      it "Should redirect to group_url if invite fails" do
        GroupsController.any_instance.stub(:invite_member).and_return(nil)
        put :notify, notify_params
        response.should redirect_to group_url(@group)
      end
      
      it "Should flash an alert to group_url if invite fails" do
        GroupsController.any_instance.stub(:invite_member).and_return(nil)
        put :notify, notify_params
        flash[:alert].should match(/Group invite faild to/)
      end      
    end # Invalid examples
  end # Notify

  # REMOVE_MEMBER ACTION TESTS -----------------------------------------
  
  describe "Remove_member tests" do
    let(:remove_params) {
      {
        id: @group.id,
        uid: @group.users.last.id
      }
    }
    
    describe "Valid examples" do
      it "Should redirect to group_url" do
        put :remove_member, remove_params      
        response.should redirect_to edit_group_url(assigns(:group))
      end 
      
      it "Should flash a success notice" do
        put :remove_member, remove_params 
        flash[:notice].should match(/Group member .* has been removed from the group, but NOT deleted from the system./)
      end

      it "Should find the matching group" do
        put :remove_member, remove_params 
        assigns(:group).id.should eq(@group.id)
      end
      
      it "Should remove the requested user from the group" do
        put :remove_member, remove_params 
        assigns(:group).users.pluck(:id).include?(@group.users.last.id).should be_false
      end
      
    end # Valid examples
    
    describe "Invalid examples" do
      it "Should redirect to sign_in, if not logged in" do
        sign_out @signed_in_user
        put :remove_member, remove_params 
        response.should redirect_to new_user_session_url
      end
         
      it "Should redirect to groups_url if bad group id" do
        remove_params[:id] = '99999'
        put :remove_member, remove_params 
        response.should redirect_to groups_url
      end

      it "Should flash an alert message if bad group id" do
        remove_params[:id] = '99999'
        put :remove_member, remove_params 
        flash[:alert].should match(/We could not find the requested group/)
      end

      it "Should redirect to groups_url if bad user id" do
        remove_params[:uid] = '99999'
        put :remove_member, remove_params
        response.should redirect_to groups_url
      end

      it "Should flash an alert message if bad user id" do
        remove_params[:uid] = '99999'
        put :remove_member, remove_params
        flash[:alert].should match(/We could not find the requested group member./)
      end
       
    end # Invalid examples
  end # Remove_member
end
