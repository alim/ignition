########################################################################
# The ProjectsController class is responsible for managing project
# resources associated with the web service. It is the primary resource
# to which other records are related. Being a primary resource allows
# us to manage, authorization for group access to a project and all its
# related records.
#
# The controller uses an injection model for relating a project to a
# a group. See lib/group_access.rb for injected methods.
########################################################################
class ProjectsController < ApplicationController
  respond_to :html

  ## CALL BACKS --------------------------------------------------------
  before_filter :authenticate_user!

  before_action :set_project, only: [:show, :edit, :update, :destroy]

  # CANCAN AUTHORIZATION -----------------------------------------------
  # This helper assumes that the instance variable @group is loaded
  # or checks Class permissions
  authorize_resource

  ######################################################################
  # GET /projects
  # GET /projects.json
  #
  # The index method displays the current users list of projects. If
  # the signed in user is a User::SERVICE_ADMIN, then all projects are
  # listed.
  ######################################################################
  def index

    # Get page number
		page = params[:page].nil? ? 1 : params[:page]

    if current_user.role == User::SERVICE_ADMIN
      @projects = Project.all.paginate(page: page,	per_page: PAGE_COUNT)
    else
      @projects = Project.in_organization(current_user).paginate(page: page,	per_page: PAGE_COUNT)
    end
  end

  ######################################################################
  # GET /projects/1
  # GET /projects/1.json
  #
  # The show method will show the project record. The corresponding
  # view will show the owner name and list of user group names
  # associated with the project.
  ######################################################################
  def show
  end

  ######################################################################
  # GET /projects/new
  #
  # The new method will show the user a new project form. It will also
  # lookup any groups that the user may have to see, if they want to
  # grant access to those groups to the user.
  ######################################################################
  def new
    @project = Project.new
  end

  ######################################################################
  # GET /projects/1/edit
  #
  # The standard edit method will display the edit form and include the
  # ability to select groups that will be given access to the project.
  ######################################################################
  def edit
  end

  ######################################################################
  # POST /projects
  #
  # The create method will create a new project and relate any selected
  # groups that the user selected.
  ######################################################################
  def create
    @project = Project.create_with_user(project_params, current_user)

    if @project.save
      @project.relate_to_organization
      redirect_to @project, notice: 'Project was successfully created.'
    else
      @verrors = @project.errors.full_messages
      render  'new'
    end
  end

  ######################################################################
  # PATCH/PUT /projects/1
  # PATCH/PUT /projects/1.json
  #
  # The update will update the Project model object including any
  # changes to the organization associated with the current user.
  ######################################################################
  def update
    if @project.update_attributes(project_params)
      @project.relate_to_organization
      redirect_to @project, notice: 'Project was successfully updated.'
    else
      @verrors = @project.errors.full_messages
      render  'edit'
    end
  end

  ######################################################################
  # DELETE /projects/1
  # DELETE /projects/1.json
  #
  # The destroy project method will delete the project, but does not
  # destroy the related groups that were given access to the project.
  ######################################################################
  def destroy
    @project.destroy
    redirect_to projects_url, notice: "Project was successfully deleted."
  end

  ## PRIVATE INSTANCE METHODS ------------------------------------------

  private

  ######################################################################
  # Use callbacks to share common setup or constraints between actions.
  ######################################################################
  def set_project
    @project = Project.find(params[:id])
  end

  ######################################################################
  # Never trust parameters from the scary internet, only allow the
  # white list through.
  ######################################################################
  def project_params
    params.require(:project).permit(:name, :description, :group_ids, :charter_doc)
  end

end
