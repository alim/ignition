require 'spec_helper'

describe GroupsController do

  include_context 'user_setup'
  include_context 'group_setup'
  include_context 'project_setup'

  # TEST SETUP ---------------------------------------------------------
  let(:find_one_user) {
    @customer = User.where(role: User::CUSTOMER).where(:account.exists => true).first
  }

  let(:find_one_group) {
    @group = Group.where(owner_id: @owner.id).first
  }

  let(:login_as_group_owner){
    sign_in @owner
    @signed_in_user = @owner
    subject.current_user.should_not be_nil
  }

  let(:login_nonowner) {
    sign_out @signed_in_user
    @signed_in_user = User.where(:id.ne => @owner.id).first
    sign_in @signed_in_user
  }

  let(:create_projects){
      3.times.each do
        FactoryGirl.create(:project, user: @signed_in_user)
      end
  }

  before(:each) {
    multi_groups_multi_users
    find_one_user
    find_one_group
    login_as_group_owner
    subject.current_user.should_not be_nil
  }

  after(:each) {
    delete_users
    Group.delete_all
    ActionMailer::Base.deliveries.clear
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
        get :index
        assigns(:groups).count.should_not eq(0)
        assigns(:groups).each {|group| @group_ids.should include(group.id)}
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

    describe "Authorization examples" do
      it "Should return success as a customer" do
        get :index
        response.should be_success
      end

      it "Should only access groups that user owns" do
        get :index
        assigns(:groups).count.should_not eq(0)
        assigns(:groups).each do |group|
          group.owner_id.should eq(@owner.id)
        end
      end

      it "Should not access any groups, if not group owner" do
        login_nonowner
        get :index
        assigns(:groups).count.should eq(0)
      end

      it "Should return all groups, if service admin" do
        login_admin
        get :index
        response.should be_success
        assigns(:groups).count.should_not eq(0)
        assigns(:groups).count.should eq(Group.count)
      end
    end # Index authorization

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
        response.should redirect_to admin_oops_url
      end

      it "Should flash an alert message, if record not found" do
        get :show, {id: '99999'}
        flash[:alert].should match(/^We are unable to find the requested Group/)
      end

      it "Should flash an alert if we cannot find a group owner" do
        @group.owner_id = '9999'
        @group.save

        get :show, show_params
        flash[:alert].should match(/You are not authorized to access the requested Group/)
      end
    end

    describe "Authorization examples" do
      it "Return success for a group owned by the user" do
        login_as_group_owner
        group = Group.where(owner_id: @owner.id).first
        get :show, {id: group.id}
        response.should be_success
      end

      it "Find the requested group owned by the user" do
        login_as_group_owner
        group = Group.where(owner_id: @owner.id).first
        get :show, {id: group.id}
        assigns(:group).id.should eq(group.id)
      end

      it "Group owner_id should match requested group owner_id" do
        login_as_group_owner
        group = Group.where(owner_id: @owner.id).first
        get :show, {id: group.id}
        assigns(:group).owner_id.should eq(@owner.id)
      end

      it "Return success for a group with different owner than admin" do
        login_admin
        group = Group.where(owner_id: @owner.id).first
        get :show, {id: group.id}
        response.should be_success
      end

      it "Find the requested group with different owner than admin" do
        login_admin
        group = Group.where(owner_id: @owner.id).first
        get :show, {id: group.id}
        assigns(:group).id.should eq(group.id)
      end

      it "Group should have different owner than admin" do
        login_admin
        group = Group.where(owner_id: @owner.id).first
        get :show, {id: group.id}
        assigns(:group).owner_id.should_not eq(@signed_in_user.id)
      end

      it "Redirect to admin_oops for a group NOT owned by the user" do
        login_nonowner
        group = Group.where(owner_id: @owner.id).first
        get :show, {id: group.id}
        response.should redirect_to admin_oops_url
      end

      it "Flash alert message for a group NOT owned by the user" do
        login_nonowner
        get :show, {id: @group.id}
        flash[:alert].should match(/You are not authorized to access the requested #{@group.class}/)
      end
    end # Show authorization examples

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
    end # Valid tests

    describe "Invalid tests" do
      it "Should redirect, if not logged in" do
        sign_out @signed_in_user
        get :new
        response.should redirect_to new_user_session_url
      end
    end # Invalid examples

    describe "Authorization examples" do
     it "Return success for a new group owned by the current_user" do
        get :new
        response.should be_success
        response.should render_template :new
      end

      it "Return success for a new group logged in as admin" do
        login_admin
        get :new
        response.should be_success
        response.should render_template :new
      end
    end # New authorization examples

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
    end # Valid tests

    describe "Invalid tests" do
      it "Should redirect, if not logged in" do
        sign_out @signed_in_user
        get :edit, edit_params
        response.should redirect_to new_user_session_url
      end

      it "Should redirect to groups_url for invalid group id" do
        get :edit, {id: '090909'}
        response.should redirect_to admin_oops_url
      end

      it "Should flash alert message for invalid group id" do
        get :edit, {id: '090909'}
        flash[:alert].should match(/We are unable to find the requested Group/)
      end
    end # Invalid tests

    describe "Authorization examples" do
      it "Return success for a group owned by the user" do
        login_as_group_owner
        group = Group.where(owner_id: @owner.id).first
        get :edit, {id: group.id}
        response.should be_success
      end

      it "Find the requested group owned by the user" do
        login_as_group_owner
        group = Group.where(owner_id: @owner.id).first
        get :edit, {id: group.id}
        assigns(:group).id.should eq(group.id)
      end

      it "Group owner_id should match requested group owner_id" do
        login_as_group_owner
        group = Group.where(owner_id: @owner.id).first
        get :edit, {id: group.id}
        assigns(:group).owner_id.should eq(@owner.id)
      end

      it "Return success for a group with different owner than admin" do
        login_admin
        group = Group.where(owner_id: @owner.id).first
        get :edit, {id: group.id}
        response.should be_success
      end

      it "Find the requested group with different owner than admin" do
        login_admin
        group = Group.where(owner_id: @owner.id).first
        get :edit, {id: group.id}
        assigns(:group).id.should eq(group.id)
      end

      it "Group should have different owner than admin" do
        login_admin
        group = Group.where(owner_id: @owner.id).first
        get :edit, {id: group.id}
        assigns(:group).owner_id.should_not eq(@signed_in_user.id)
      end

      it "Redirect to admin_oops for a group NOT owned by the user" do
        login_nonowner
        get :edit, {id: @group.id}
        response.should redirect_to admin_oops_url
      end

      it "Flash alert message for a group NOT owned by the user" do
        login_nonowner
        get :edit, {id: @group.id}
        flash[:alert].should match(/You are not authorized to access the requested #{@group.class}/)
      end
    end # Edit authorization examples
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

      it "Should relate the correct resources to the group" do
        create_projects
        project_ids = Project.all.pluck(:id)
        valid_group_params[:group][:resource_ids] = project_ids
        post :create, valid_group_params
        assigns(:group).project_ids.sort.should eq(project_ids.sort)
      end

      it "Should relate the correct number of resources to the group" do
        create_projects
        project_ids = Project.all.pluck(:id)
        valid_group_params[:group][:resource_ids] = project_ids
        post :create, valid_group_params
        assigns(:group).projects.count.should eq(project_ids.count)
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

    describe "Authorization examples" do
      it "Return success for a group owned by the user" do
        login_as_group_owner
        post :create, valid_group_params
        response.should redirect_to group_url(assigns(:group))
      end

      it "New group should be owned by the user" do
        login_as_group_owner
        post :create, valid_group_params
        assigns(:group).owner_id.should eq(@owner.id)
      end
    end # Create authorization examples
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

      it "Should create new user records for each email address" do
        put :update, update_params
        new_members.split.each do |email|
          assigns(:group).users.where(email: email).first.should be_present
        end
      end

      it "Should allow us to delete an existing member" do
        member_count = @group.users.count + new_members.split.count
        put :update, update_params
        assigns(:group).users.count.should == member_count

        put :update, {
          id: @group.id,
          group: { user_ids: ["#{@group.users.last.id}","#{@group.users.first.id}"] }
        }
        assigns(:group).users.count.should == (member_count - 2)
      end

      it "Should notify each user of their account" do
        put :update, update_params
        ActionMailer::Base.deliveries.each do |delivery|
          new_members.should match(/#{delivery.to}/)
        end
      end

      it "Should relate the correct resources to the group" do
        create_projects
        project_ids = Project.all.pluck(:id)
        update_params[:group][:resource_ids] = project_ids
        put :update, update_params
        assigns(:group).project_ids.sort.should eq(project_ids.sort)
      end

      it "Should relate the correct number of resources to the group" do
        create_projects
        project_ids = Project.all.pluck(:id)
        update_params[:group][:resource_ids] = project_ids
        put :update, update_params
        assigns(:group).projects.count.should eq(project_ids.count)
      end

    end # Valid update examples

    describe "Invalid update examples" do
      it "Should redirect to sign_in, if not logged in" do
        sign_out @signed_in_user
        put :update, update_params
        response.should redirect_to new_user_session_url
      end

      it "Should redirect to admin_oops_url if user not found" do
        params = update_params
        params[:id] = '99999'
        put :update, params
        response.should redirect_to admin_oops_url
      end

      it "Should flash error message, if group not found" do
        params = update_params
        params[:id] = '99999'
        put :update, params
        flash[:alert].should match(/We are unable to find the requested Group/)
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

    describe "Authorization examples" do
      let(:set_group_owner) {
        @group.owner_id = @owner.id
        @group.save
      }

      it "Return success for a group owned by the user" do
        login_as_group_owner
        set_group_owner
        put :update, update_params
        response.should redirect_to group_url(@group)
      end

      it "Find the requested group owned by the user" do
        login_as_group_owner
        set_group_owner
        put :update, update_params
        assigns(:group).id.should eq(@group.id)
      end

      it "Group owner_id should match requested group owner_id" do
        login_as_group_owner
        set_group_owner
        put :update, update_params
        assigns(:group).owner_id.should eq(@owner.id)
      end

      it "Return success for a group with different owner than admin" do
        login_admin
        set_group_owner
        put :update, update_params
        response.should redirect_to group_url(@group)
      end

      it "Find the requested group with different owner than admin" do
        login_admin
        set_group_owner
        put :update, update_params
        assigns(:group).id.should eq(@group.id)
      end

      it "Group should have different owner than admin" do
        login_admin
        set_group_owner
        put :update, update_params
        assigns(:group).owner_id.should_not eq(@signed_in_user.id)
      end

      it "Redirect to admin_oops for a group NOT owned by the user" do
        login_nonowner
        put :update, update_params
        response.should redirect_to admin_oops_url
      end

      it "Flash alert message for a group NOT owned by the user" do
        login_nonowner
        put :update, update_params
        flash[:alert].should match(/You are not authorized to access the requested #{@group.class}/)
      end
    end # Update authorization examples
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

      it "Should unrelate all group resources" do
        # Associate resources to the group
        project = FactoryGirl.create(:project, user: @signed_in_user)
        @group.send(Group::RESOURCE_CLASS.downcase.pluralize) << project

        resources = @group.send(Group::RESOURCE_CLASS.downcase.pluralize)
        rcount = resources.count
        rcount.should_not eq(0)

        expect{
          delete :destroy, destroy_params
        }.to_not change(Object.const_get(Group::RESOURCE_CLASS), :count).by(-1)

        Object.const_get(Group::RESOURCE_CLASS).count.should eq(rcount)
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
        response.should redirect_to admin_oops_url
      end

      it "Should flash an error message, if no group record found" do
        params = destroy_params
        params[:id] = '00999'
        delete :destroy, params
        flash[:alert].should match(/We are unable to find the requested Group/)
      end
    end # Invalid examples

    describe "Authorization examples" do
      it "Should redirect to groups_url, upon succesfull deletion of owned group" do
        delete :destroy, destroy_params
        response.should redirect_to groups_url
      end

      it "Deleted group should have same owner id as login" do
        delete :destroy, destroy_params
        assigns(:group).owner_id.should eq(@signed_in_user.id)
      end

      it "Should redirect to groups_url, upon succesfull deletion of group as admin" do
        login_admin
        delete :destroy, destroy_params
        response.should redirect_to groups_url
      end

      it "Deleted group should have different owner id from admin" do
        login_admin
        delete :destroy, destroy_params
        assigns(:group).owner_id.should_not eq(@signed_in_user.id)
      end

      it "Should redirect to admin oops for non-owner access" do
        login_nonowner
        delete :destroy, destroy_params
        response.should redirect_to admin_oops_url
      end

      it "Should flash alert for non-owner access" do
        login_nonowner
        delete :destroy, destroy_params
        flash[:alert].should match(/You are not authorized to access the requested #{@group.class}/)
      end
    end # Authorization examples for delete
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

      it "Should redirect to admin_oops_url if bad group id" do
        notify_params[:id] = '99999'
        put :notify, notify_params
        response.should redirect_to admin_oops_url
      end

      it "Should flash an alert message if bad group id" do
        notify_params[:id] = '99999'
        put :notify, notify_params
        flash[:alert].should match(/We are unable to find the requested Group/)
      end

      it "Should redirect to admin_oops_url if bad user id" do
        notify_params[:uid] = '99999'
        put :notify, notify_params
        response.should redirect_to admin_oops_url
      end

      it "Should flash an alert message if bad user id" do
        notify_params[:uid] = '99999'
        put :notify, notify_params
        flash[:alert].should match(/We are unable to find the requested User/)
      end

      it "Should redirect to group_url if invite fails" do
        GroupsController.any_instance.stub(:invite_member).and_return(nil)
        put :notify, notify_params
        response.should redirect_to group_url(@group)
      end

      it "Should flash an alert to group_url if invite fails" do
        Group.any_instance.stub(:invite_member).and_return(nil)
        put :notify, notify_params
        flash[:alert].should match(/Group invite failed/)
      end
    end # Invalid examples

    describe "Authorization examples" do
      it "Should redirect to group_url, upon succesfull notification of owned group" do
        put :notify, notify_params
        response.should redirect_to group_url(assigns(:group))
      end

      it "Notified group should have same owner id as login" do
        put :notify, notify_params
        assigns(:group).owner_id.should eq(@signed_in_user.id)
      end

      it "Should redirect to group_url, upon succesfull notification of group as admin" do
        login_admin
        put :notify, notify_params
        response.should redirect_to group_url(assigns(:group))
      end

      it "Notified group should have different owner id from admin" do
        login_admin
        put :notify, notify_params
        assigns(:group).owner_id.should_not eq(@signed_in_user.id)
      end

      it "Should redirect to admin oops for non-owner access" do
        login_nonowner
        put :notify, notify_params
        response.should redirect_to admin_oops_url
      end

      it "Should flash alert for non-owner access" do
        login_nonowner
        put :notify, notify_params
        flash[:alert].should match(/You are not authorized to access the requested #{@group.class}/)
      end
    end # Authorization examples for notify
  end # Notify

end
