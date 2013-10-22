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

  ## RESCUE SETTINGS ---------------------------------------------------
	rescue_from Mongoid::Errors::DocumentNotFound, with: :missing_document
  rescue_from CanCan::AccessDenied, with: :access_denied
  
  
  ## CALL BACKS --------------------------------------------------------
  before_filter :authenticate_user!
  
  before_action :set_project, only: [:show, :edit, :update, :destroy]
  before_action :set_project_class


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
    if current_user.role == User::SERVICE_ADMIN
      @projects = Project.all
    else
      @projects = current_user.projects
    end
  end

  # GET /projects/1
  # GET /projects/1.json
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

  # GET /projects/1/edit
  def edit
  end

  # POST /projects
  # POST /projects.json
  def create
    @project = Project.new(project_params)

    respond_to do |format|
      if @project.save
        format.html { redirect_to @project, notice: 'Project was successfully created.' }
        format.json { render action: 'show', status: :created, location: @project }
      else
        format.html { render action: 'new' }
        format.json { render json: @project.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /projects/1
  # PATCH/PUT /projects/1.json
  def update
    respond_to do |format|
      if @project.update(project_params)
        format.html { redirect_to @project, notice: 'Project was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @project.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /projects/1
  # DELETE /projects/1.json
  def destroy
    @project.destroy
    respond_to do |format|
      format.html { redirect_to projects_url }
      format.json { head :no_content }
    end
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
	# The set_project_class method sets an instance variable for the CSS
	# class that will highlight the menu item. 
	######################################################################
  def set_project_class
    @project_active = "class=active" 
  end

  ######################################################################
  # Never trust parameters from the scary internet, only allow the 
  # white list through.
  ######################################################################
  def project_params
    params.require(:project).permit(:name, :description, :user_id, :group_id)
  end
  
end
