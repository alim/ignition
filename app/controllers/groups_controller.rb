########################################################################
# The GroupsController is responsible for managing the actions 
# associated with managing user groups that will provide group access
# to a subset of system resources. 
########################################################################
class GroupsController < ApplicationController
  include GroupRelations
  
  # RESCUE SETTINGS ----------------------------------------------------
	rescue_from Mongoid::Errors::DocumentNotFound, with: :missing_document
  rescue_from CanCan::AccessDenied, with: :access_denied
	
	# BEFORE CALLBACKS ---------------------------------------------------
	before_filter :authenticate_user!
	
  before_action :set_group, only: [:show, :edit, :update, :notify, 
  	:remove_member, :destroy]
  	
  before_action :set_group_class

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
    if current_user.role == User::SERVICE_ADMIN
      @groups = Group.all
    else
      @groups = Group.where(owner_id: current_user.id)
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
puts "\n\n[show] Resources.count = #{@resources.count} and name= #{@resources.name}\n\n"	  
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
  	respond_to do |format|
		  @group = current_user.groups.new(group_params)
			@group.owner_id = current_user.id

			if @group.save
			
				# Lookup membership list to see if they already exists
				@members = lookup_users(@group)
			
				# Create and notify group members of their inclusion into the group
				create_notify(@members, @group) if @members.present?
	          	  		
	      # Relate resources from injected methods in GroupRelations 
			  # module. It relates the current set of resources to the group
	      relate_resources(resource_ids: params[:group][:resource_ids],
	        group: @group, class: Group::RESOURCE_CLASS)
	      
	      format.html { redirect_to @group, notice: 'Group was successfully created.' }
	      format.json { render action: 'show', status: :created, location: @group }
	    else
	    	@verrors = @group.errors.full_messages
	      format.html { render action: 'new' }
	      format.json { render json: @group.errors, status: :unprocessable_entity }
	    end
    end
  end

	######################################################################
  # PATCH/PUT /groups/1
  # PATCH/PUT /groups/1.json
  #
  # The update action allows the user to update the group attributes,
  # remove group members and add new group members.
  ######################################################################
  def update
    respond_to do |format|
      if @group.update_attributes(group_params)
      
			  # Relate resources from injected methods in GroupRelations 
			  # module. It relates the current set of resources to the group
			  relate_resources(resource_ids: params[:group][:resource_ids],
	        group: @group, class: Group::RESOURCE_CLASS)
			
			  # Lookup membership list to see if they already exists
			  @members = lookup_users(@group)
		
			  # Create and notify group members of their inclusion into the group
			  create_notify(@members, @group) if @members.present?      
      
        format.html { redirect_to @group, notice: 'Group was successfully updated.' }
        format.json { head :no_content }
      else
        @verrors = @group.errors.full_messages
        format.html { render action: 'edit' }
        format.json { render json: @group.errors, status: :unprocessable_entity }
      end
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
		# Unrelate the group resources
		unrelate_resources
	
	  @group.destroy
	  respond_to do |format|
	    format.html { redirect_to groups_url, notice: "Group was successfully deleted." }
	    format.json { head :no_content }
	  end
  end

	## CUSTOM ACTIONS ----------------------------------------------------
	
	######################################################################
	# PUT /groups/1/notify
	#
	# The notify method will resend a group invite notification message
	# to a single group member and re-display the show template.
	######################################################################
	def notify
    respond_to do |format|	
	    @user = @group.users.find(params[:uid])
	
	    if invite_member(@group, @user)			
		    format.html { redirect_to @group, 
		      notice: "Group invite resent to #{@user.email}."}
		    format.json { head :no_content }
	    else
		    format.html { redirect_to @group, 
		      alert: "Group invite faild to #{@user.email}."}
		    format.json { head :no_content }
	    end
	  end    
	end

	######################################################################
	# PUT groups/1/remove_member
	#
	# The remove_member method will remove one group member.
	######################################################################
	def remove_member

    respond_to do |format|
    	# Delete the user association
    	user = User.find(params[:uid])
    	@group.users.delete(user)
    	@group.reload
      
  		format.html { redirect_to edit_group_url(@group), 
  		  notice: "Group member #{user.email} has been removed from the group, but NOT deleted from the system."}
  		format.json { head :no_content }
	  end

	end


	## PROTECTED INSTANCE METHODS ----------------------------------------
	
	protected

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
  	plen = 12

  	members.each do |member, user|
  		if user.nil?
  			# Create a new user
  			new_password = Devise.friendly_token.first(plen)
  			new_user = User.create!(first_name: '*None*', last_name: '*None*',
  				role: User::CUSTOMER, email: member.dup, password: new_password, 
  				password_confirmation: new_password, phone: '888.555.1212')
				
				# Associate new user to the group
				group.users << new_user
				
  			# Email user
  			GroupMailer.member_email(new_user, new_password, group).deliver
  		else
  			# Associate User record to group
  			group.users << user
  			
  			# Notify current user that they are now a member of the group
  			# We do not need to send the user password, since they should
  			# have it.
  			GroupMailer.member_email(user, nil, group).deliver
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
    	# Create a new password
  		new_password = Devise.friendly_token.first(plen)

			# Email user
			GroupMailer.member_email(user, new_password, group).deliver
  	else 		
			# Notify current user that they are now a member of the group
			GroupMailer.member_email(user, nil, group).deliver
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
  	users = {} 		# Hash for returning results

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

	## -------------------------------------------------------------------
	# Actions for updating resource relationships to the group.
	# You will need to customize these methods to ensure that a group
	# has access to the primary service resource.
	## -------------------------------------------------------------------
	
	######################################################################
	# The owned_resource method will set an instance variable called 
	# @resources to hold an array of hashes. Each array element holds
	# resource information in a hash. The user can select multiple 
	# resources to share with the group. This instance variable is used 
	# by the form partial. The example array of hash values are
	# shown below:
	#
	# @resources[0] = { id: 1, related: true, label: 'name'} 
	#
	# The 'related' key/value is used to indicae whether the resource 
	# is already related to the group. Its value can either be true or 
	# false. The 'label' key/value is text choice that will be displayed
	# to the user.
	#
	# This method also sets an instance variable for the @resource_name
	# to the name of the resource you are relating to the group.
	#
	# You will need to customize this method to list the resources that
	# you want to share with the group.
	######################################################################
#	def owned_resources
#	
#		# Dummy resource name for demonstration purposes
#		@resource_name = 'Shared Resource'
#		
#		# Dummy resources variable for demonstration purposes
#		@resources = [
#			{id: 1, related: true, label: 'Resource 1'},
#			{id: 2, related: false, label: 'Resource 2'},
#			{id: 3, related: true, label: 'Resource 3'},
#		]
#		return @resources
#		
#	end
	
	######################################################################
	# The relate_resources method will relate the requested resources to 
	# the group. It is expecting an array of resource id's. It will then
	# add each resource to the group.
	#
	# You will need to customize this method to relate the resource that
	# you wish to use.
	######################################################################
#	def relate_resources(resources)
#		return true
#	end
	
	######################################################################
	# The unrelate_resources method will un-elate the all resources  
	# from the group.
	#
	# You will need to customize this method to relate the resource that
	# you wish to use.
	######################################################################
	def unrelate_resources
		return true
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
	# The set_group_class method sets an instance variable for the CSS
	# class that will highlight the menu item. 
	######################################################################
	def set_group_class
		@groups_active = "class=active" 
	end
	
	######################################################################
  # Never trust parameters from the scary internet, only allow the 
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
  	respond_to do |format| 
  		format.html { redirect_to groups_url, alert: msg }
  		format.json { head :no_content }
  	end
  end 
  
  ######################################################################
  # The missing_document method is the controller method for catching
  # a Mongoid Mongoid::Errors::DocumentNotFound exception across all
  # controller actions. User will be redirected to the groups#index view
  ######################################################################
  def missing_document(exception)
    groups_alert("We are unable to find the requested #{exception.klass} - ID ##{exception.params[0]}")
  end
  
end
