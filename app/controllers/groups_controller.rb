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
       @group.create_notify

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
    @group.remove_members(params[:group][:user_ids])

    if @group.update_attributes(group_params)

      # Relate resources from injected methods in GroupRelations
      # module. It relates the current set of resources to the group
      relate_resources(resource_ids: params[:group][:resource_ids],
        group: @group, class: Group::RESOURCE_CLASS)

      # Create and notify group members of their inclusion into the group
       @group.create_notify

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

    if @group.invite_member(@user)
      flash[:notice] = "Group invite resent to #{@user.email}."
    else
      flash[:alert] = "Group invite failed to #{@user.email}."
    end
    redirect_to @group
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
