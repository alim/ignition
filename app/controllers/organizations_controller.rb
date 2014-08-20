########################################################################
# The OrganizationsController is responsible for managing the actions
# associated with managing user organizations that will provide organization access
# to a subset of system resources.
########################################################################
class OrganizationsController < ApplicationController
  respond_to :html

  # BEFORE CALLBACKS ---------------------------------------------------
  before_filter :authenticate_user!

  before_action :set_organization, only: [:show, :edit, :update, :notify,
    :remove_member, :destroy]

  # CANCAN AUTHORIZATION -----------------------------------------------
  # This helper assumes that the instance variable @organization is loaded
  # or checks Class permissions
  authorize_resource

  ######################################################################
  # GET /organizations
  # GET /organizations.json
  #
  # The index action will check to see if an organization is currently
  # related to the current user. If one exists, then the organizational
  # record is shown.
  ######################################################################
  def index
    # Get page number
    page = params[:page].nil? ? 1 : params[:page]

    if current_user.admin?
      @organizations = Organization.all.paginate(page: page, per_page: PAGE_COUNT)
    else
      if current_user.organization
        redirect_to current_user.organization
      else
        redirect_to new_organization_path
      end
    end
  end

  ######################################################################
  # GET /organizations/1
  # GET /organizations/1.json
  #
  # Shows the organization information and the list of organization members. It also
  # allows you to re-send the organization invite to a given user.
  ######################################################################
  def show
    @user = User.find(@organization.owner_id)
    @resources = @organization.managed_classes
  end

  ######################################################################
  # GET /organizations/new
  #
  # Since we support a resource based authorization system, the new
  # method should show the user a list of top-level resources to which
  # the organization has access. For example, you might have a list of Projects
  # to which you want to give the organization access. A list of Project
  # resources should be shown to the user.
  ######################################################################
  def new
    @organization = Organization.new
  end

  ######################################################################
  # GET /organizations/1/edit
  #
  # This action present the edit view with the list of resources that
  # are currently owned by the signed in user. These resources can be
  # selected by the user for sharing with the organization.
  ######################################################################
  def edit
  end

  ######################################################################
  # POST /organizations
  # POST /organizations.json
  #
  # The create method will create the organization add the current user to
  # the organization. It will then add any members to the organization that were
  # specified by the user. If the user is not a member, then a new user
  # will be created. All members will be notified by email.
  ######################################################################
  def create
    @organization = Organization.create_with_owner(organization_params, current_user)

    if @organization.save
      @organization.relate_classes
      @organization.create_notify

      redirect_to @organization, notice: 'Organization was successfully created.'
    else
      @verrors = @organization.errors.full_messages
      render  'new'
    end
  end

  ######################################################################
  # PATCH/PUT /organizations/1
  #
  # The update action allows the user to update the organization attributes,
  # remove organization members and add new organization members.
  ######################################################################
  def update
    @organization.remove_members(params[:organization][:user_ids])

    if @organization.update_attributes(organization_params)
      @organization.relate_classes
      @organization.create_notify

      redirect_to @organization, notice: 'Organization was successfully updated.'
    else
      @verrors = @organization.errors.full_messages
      render  'edit'
    end
  end

  ######################################################################
  # DELETE /organizations/1
  # DELETE /organizations/1.json
  #
  # The standard destroy action with a call to unrelate all resources
  # that are currently related to the organization. Depending on the ORM that
  # is being used, the separate call to the helper method
  # unrelate_resources might not be needed.
  ######################################################################
  def destroy
    @organization.unrelate_classes
    @organization.destroy
    redirect_to organizations_url, notice: "Organization was successfully deleted."
  end

  ## CUSTOM ACTIONS ----------------------------------------------------

  ######################################################################
  # PUT /organizations/1/notify
  #
  # The notify method will resend a organization invite notification message
  # to a single organization member and re-display the show template.
  ######################################################################
  def notify
    @user = @organization.users.find(params[:uid])
    if @organization.invite_member(@user)
      flash[:notice] = "Organization invite resent to #{@user.email}."
    else
      flash[:alert] = "Organization invite failed to #{@user.email}."
    end
    redirect_to @organization
  end

  ## PRIVATE INSTANCE METHODS ------------------------------------------

  private

  ####################################################################
  # Use callbacks to share common setup or constraints between actions.
  # We do the following actions:
  # * Try to lookup the resource
  # * Catch the error if not found and set instance variable to nil
  ####################################################################
  def set_organization
    @organization = Organization.find(params[:id])
  end

  ######################################################################
  # Never trust parameters from the scary Internet, only allow the
  # white list through.
  ######################################################################
  def organization_params
    params.require(:organization).permit(:name, :description, :owner_id, :members)
  end

end
