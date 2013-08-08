########################################################################
# The GroupsController is responsible for managing the actions 
# associated with managing user groups that will provide group access
# to a subset of system resources. 
########################################################################
class GroupsController < ApplicationController
	before_filter :authenticate_user!
	
  before_action :set_group, only: [:show, :edit, :update, :destroy]

	######################################################################
  # GET /groups
  # GET /groups.json
  #
  # Standard listing of user groups and membership.
  ######################################################################
  def index
    @groups = Group.all

  end

	######################################################################
  # GET /groups/1
  # GET /groups/1.json
  #
  # Shows the group information and the list of group members
  ######################################################################
  def show
  	
		if @group.present?
		
			@user = User.find(@group.owner_id)
			@owner_email = @user.email
			
			# Build hash of users assoicated with the group
			@users = []
			@group.users.each do |user_id|
				begin
					user = User.find(user_id)
					@users << user
				rescue Mongoid::Errors::DocumentNotFound
					display_alert("Unable to find User information for group - #{@gruop.name}.")
				end
			end
			
		else
			display_alert('Unable to find Group information.')
		end
  	
  end

  # GET /groups/new
  def new
    @group = Group.new
  end

  # GET /groups/1/edit
  def edit
  end

  # POST /groups
  # POST /groups.json
  def create
  	respond_to do |format|

  		@group = Group.new(group_params)
  		@group.owner_id = current_user.id

		  current_user.groups << @group
		
      if @group.save
      	 puts "###> Group owner = #{@group.owner_id}"
      	  		
        format.html { redirect_to @group, notice: 'Group was successfully created.' }
        format.json { render action: 'show', status: :created, location: @group }
      else
        format.html { render action: 'new' }
        format.json { render json: @group.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /groups/1
  # PATCH/PUT /groups/1.json
  def update
    respond_to do |format|
      if @group.update(group_params)
        format.html { redirect_to @group, notice: 'Group was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @group.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /groups/1
  # DELETE /groups/1.json
  def destroy
    @group.destroy
    respond_to do |format|
      format.html { redirect_to groups_url }
      format.json { head :no_content }
    end
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
    	begin
      	@group = Group.find(params[:id])
      rescue Mongoid::Errors::DocumentNotFound
      	@group = nil
      end
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def group_params
      params.require(:group).permit(:name, :description, :owner_id)
    end
    
    def display_alert(msg)
    	respond_to do |format|
				format.html { redirect_to admin_oops_url, alert: msg }
      	format.json { render json: @group.errors, status: :unprocessable_entity }
      end
    end
    
    def display_error(msg)
    	respond_to do |format|
    		flash[:error] = msg
				format.html { redirect_to admin_oops_url }
      	format.json { render json: @group.errors, status: :unprocessable_entity }
      end
    end
end
