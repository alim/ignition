class UsersController < ApplicationController

	# Before filters -----------------------------------------------------
	before_filter :authenticate_user!
	
  before_action :set_user, only: [:show, :edit, :update, :destroy]
  before_action :set_users_class
  	
	def index
		@users = User.all
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
