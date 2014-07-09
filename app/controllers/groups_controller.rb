########################################################################
# The GroupsController is responsible for managing the actions
# associated with managing user groups that will provide group access
# to a subset of system resources.
########################################################################
class GroupsController < ApplicationController
  include GroupRelations

  respond_to :html

  # BEFORE CALLBACKS ---------------------------------------------------
  before_filter :authenticate_user!

  before_action :set_group, only: [:show, :edit, :update, :notify,
    :remove_member, :destroy]

  # CANCAN AUTHORIZATION -----------------------------------------------
  # This helper assumes that the instance variable @group is loaded
  # or checks Class permissions
  authorize_resource

  ######################################################################
  # GET /groups
  # GET /groups.json
  #
  # Standard listing of user groups and membership.
  ######################################################################
  def index
    # Get page number
    page = params[:page].nil? ? 1 : params[:page]

    if current_user.role == User::SERVICE_ADMIN
      @groups = Group.all.paginate(page: page, per_page: PAGE_COUNT)
    else
      @groups = Group.where(owner_id: current_user.id).paginate(
        page: page,  per_page: PAGE_COUNT)
    end
  end

  ######################################################################
  # GET /groups/1
  # GET /groups/1.json
  #
  # Shows the group information and the list of group members. It also
  # allows you to re-send the group invite to a given user.
  ######################################################################
  def show
    @user = User.find(@group.owner_id)
    @owner_email = @user.email

    # Get list of associated users and resources
    @users = @group.users
    @resources = @group.send(Group::RESOURCE_CLASS.downcase.pluralize)
  end

  ######################################################################
  # GET /groups/new
  #
  # Since we support a resource based authorization system, the new
  # method should show the user a list of top-level resources to which
  # the group has access. For example, you might have a list of Projects
  # to which you want to give the group access. A list of Project
  # resources should be shown to the user.
  ######################################################################
  def new
    @group = Group.new
  end

  ######################################################################
  # GET /groups/1/edit
  #
  # This action present the edit view with the list of resources that
  # are currently owned by the signed in user. These resources can be
  # selected by the user for sharing with the group.
  ######################################################################
  def edit
  end

  ######################################################################
  # POST /groups
  # POST /groups.json
  #
  # The create method will create the group add the current user to
  # the group. It will then add any members to the group that were
  # specified by the user. If the user is not a member, then a new user
  # will be created. All members will be notified by email.
  ######################################################################
  def create
    @group = current_user.groups.new(group_params)
    @group.owner_id = current_user.id

    if @group.save
      # Create and notify group members of their inclusion into the group
      create_notify(lookup_users(@group), @group)

      # Relate resources from injected methods in GroupRelations
      # module. It relates the current set of resources to the group
      relate_resources(resource_ids: params[:group][:resource_ids],
        group: @group, class: Group::RESOURCE_CLASS)

      redirect_to @group, notice: 'Group was successfully created.'
    else
      @verrors = @group.errors.full_messages
      render action: 'new'
    end
  end

  ######################################################################
  # PATCH/PUT /groups/1
  #
  # The update action allows the user to update the group attributes,
  # remove group members and add new group members.
  ######################################################################
  def update
    remove_members(params[:group][:user_ids], @group)

    if @group.update_attributes(group_params)

      # Relate resources from injected methods in GroupRelations
      # module. It relates the current set of resources to the group
      relate_resources(resource_ids: params[:group][:resource_ids],
        group: @group, class: Group::RESOURCE_CLASS)

      # Create and notify group members of their inclusion into the group
      create_notify(lookup_users(@group), @group)

      redirect_to @group, notice: 'Group was successfully updated.'
    else
      @verrors = @group.errors.full_messages
      render action: 'edit'
    end
  end

  ######################################################################
  # DELETE /groups/1
  # DELETE /groups/1.json
  #
  # The standard destroy action with a call to unrelate all resources
  # that are currently related to the group. Depending on the ORM that
  # is being used, the separate call to the helper method
  # unrelate_resources might not be needed.
  ######################################################################
  def destroy
    @group.destroy
    redirect_to groups_url, notice: "Group was successfully deleted."
  end

  ## CUSTOM ACTIONS ----------------------------------------------------

  ######################################################################
  # PUT /groups/1/notify
  #
  # The notify method will resend a group invite notification message
  # to a single group member and re-display the show template.
  ######################################################################
  def notify
    @user = @group.users.find(params[:uid])

    if invite_member(@group, @user)
      flash[:notice] = "Group invite resent to #{@user.email}."
    else
      flash[:alert] = "Group invite faild to #{@user.email}."
    end
    redirect_to @group
  end


  ## PROTECTED INSTANCE METHODS ----------------------------------------

  protected

  ######################################################################
  # The remove_member method will remove selected group members
  # The parameter is a list of group members that represents an array,
  # which includes user ID's of the members to disassociate from the
  # group
  ######################################################################
  def remove_members(members, group)
    if members.present?
      members.each do |uid|
        user = User.find(uid)
        group.users.delete(user)
      end
      group.reload
    end
  end


  ######################################################################
  # The create_notify method will take a hash of email addresses and
  # User records. For each email address that has nil user record, this
  # method will create a new User record for the requested member. The
  # new user will be notified of thier new account. Each User record
  # in the hash parameter and each newly created user will be associated
  # with the current group. The method takes two parameters
  #
  # * members - hash of email addresses and User records - nil of no User present for email address
  # * group - Group object to which we associate each user
  ######################################################################
  def create_notify(members, group)
    if members.present?
      plen = 12

      members.each do |member, user|
        if user.nil?
          # Create a new user
          new_password = Devise.friendly_token.first(plen)
          user = User.create!(first_name: '*None*', last_name: '*None*',
            role: User::CUSTOMER, email: member.dup, password: new_password,
            password_confirmation: new_password, phone: '888.555.1212')
        end

        group.users << user
        GroupMailer.member_email(user, group).deliver
      end
    end
  end

  ######################################################################
  # The invite_member method will resend an membership notification
  # to an existing member. If the member has not ever logged into the
  # service the member will be sent a new password.
  #
  # * group - Group object to which we associate each user
  # * user - User object to notify
  ######################################################################
  def invite_member(group, user)
    plen = 12

    if user.sign_in_count == 0
      user.password = user.password_confirmation = Devise.friendly_token.first(plen)

      if user.save
        GroupMailer.member_email(user, group).deliver
      else
        groups_alert("We could not reset the password for User - #{user.email}")
      end
    else
      # Notify current user that they are now a member of the group
      GroupMailer.member_email(user, group).deliver
    end
  end

  ######################################################################
  # The lookup_user method will take an string of white-space separated
  # email addresses and return a hash based on the email addresses
  # as keys. The value of the hash will be a User or nil, depending on
  # whether the email address indicates a current user. The method will
  # return HASH, if it can successfully process all user email addresses
  # or nil if it cannot. The method will check for valid email
  # address format, while processing. The method also takes the Group
  # record as the parameter. It assumes that group.members holds the
  # email list.
  ######################################################################
  def lookup_users(group)
    users = {}     # Hash for returning results

    if group.members.present?
      elist = group.members.split

      # Look for a current user
      elist.each do |email|
        if (user = User.where(email: email).first).present?
          users[email] = user
        else
          users[email] = nil
        end
      end
    end
    users
  end


  ## PRIVATE INSTANCE METHODS ------------------------------------------

  private

  ####################################################################
  # Use callbacks to share common setup or constraints between actions.
  # We do the following actions:
  # * Try to lookup the resource
  # * Catch the error if not found and set instance variable to nil
  ####################################################################
  def set_group
    @group = Group.find(params[:id])
  end

  ######################################################################
  # Never trust parameters from the scary Internet, only allow the
  # white list through.
  ######################################################################
  def group_params
    params.require(:group).permit(:name, :description, :owner_id, :members)
  end

  ######################################################################
  # The groups_alert method will display an alert message and redirect
  # the user to the groups#index view.
  ######################################################################
  def groups_alert(msg)
    redirect_to groups_url, alert: msg
  end
end
