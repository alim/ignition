########################################################################
# The UsersController is the administrative controller for managing
# users of the web service. It is targeted for the service administrator
# and does not take the place of the Devise controller. The route is
# to this controller has been set to be contained within the /admin
# namespace.
########################################################################
class UsersController < ApplicationController

	layout 'admin' # Default layout for controller actions

	# Before filters -----------------------------------------------------
	before_filter :authenticate_user!
	
  before_action :set_user, only: [:show, :edit, :update, :destroy]
  before_action :set_users_class
  	
  ######################################################################
  # The index action will present a list of system users. It will allow
  # the system administrator to search for an acount by:
  # 
  # * email 
  # * frst_name
  # * last_name
  #
  # It will also enable filtering the view by user roles. All results
  # will be paginated. This action is designed only to be used via 
  # a web interface.
  ######################################################################
	def index
		@search_options = [
			['Email', 'email'], 
			['First name', 'first_name'],
			['Last name', 'last_name']
		]
		
		# Check to see if we want to search for a subset of users
		if params[:search].present? && params[:stype].present?
			
			# Check for the type of search we are doing
			case params[:stype]
			when 'email'
				@users = User.by_email(params[:search])
			when 'first_name'
				@users = User.by_first_name(params[:search])
			when 'last_name'	
				@users = User.by_last_name(params[:search])
			else # Unrecognized search type so return all
				@users = User.all
			end
			
		else # No search criteria, so we start off with all Users
		  @users = User.all
		end

		if params[:role_filter].present?
		  if params[:role_filter] == 'customer'
        @users =  @users.by_role(User::CUSTOMER)
		  elsif params[:role_filter] == 'service_admin'
        @users =  @users.by_role(User::SERVICE_ADMIN)
		  end
		end
		
	end
	
	def show
		
	end
	
	def edit
	end
	
	## PRIVATE INSTANCE METHODS ------------------------------------------
	private

	####################################################################
  # Use callbacks to share common setup or constraints between actions.
  # We do the following actions:
  # * Try to lookup the resource
  # * Catch the error if not found and set instance variable to nil
  ####################################################################
  def set_user
  	begin
    	@user = User.find(params[:id])
    rescue Mongoid::Errors::DocumentNotFound
    	@user = nil
    end
  end

	
	######################################################################
	# The set_users_class method sets an instance variable for the CSS
	# class that will highlight the menu item. 
	######################################################################
	def set_users_class
		@users_active = "class=active" 
	end
end
