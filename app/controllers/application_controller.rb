class ApplicationController < ActionController::Base
  # Include module for displaying alert messages
  include Oops

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  
  layout :layout_by_resource

	before_filter :configure_permitted_parameters, if: :devise_controller?

  before_filter :set_menu_active

	## INSTANCE METHODS --------------------------------------------------

	######################################################################
	# A Devise method override that redirects the user to the home_url
	# after they have signed out the system.
	######################################################################
	def after_sign_out_path_for(resource)
		root_url
	end	

	######################################################################
	# The after_sign_in_path_for method will check to see if there the
	# user needs to fill out their profile information. If yes, they are
	# redirected to the edit page for the user information.
	#####################################################################
	def after_sign_in_path_for(resource)
		if resource.is_a?(User) && (resource.first_name == '*None*' || 
			resource.last_name == '*None*')
			edit_user_registration_path
		else
			super
			admin_url
		end
	end
	
	######################################################################
	# This before_filter method is responsible for setting a menu item
	# to active. We can add multiple check blocks to determine which
	# controller and which action is active. We can then set an instance
	# variable for toggling the a CSS class to active.
	######################################################################
	def set_menu_active
	  if self.is_a?(Devise::RegistrationsController) && user_signed_in? && 
	    params[:action] == 'edit'
	    @account_active="class=active" 
	  end
	end

	## PROTECTED METHODS -------------------------------------------------
	
  protected

	######################################################################
	# Devise strong parameters method for allowing additional attributes
	# to be mass updated in the User model. See the Devise README file for
	# more details.
	######################################################################
	def configure_permitted_parameters
    devise_parameter_sanitizer.for(:account_update) { |u| u.permit(
    	:email, :password, :password_confirmation, :current_password,
    	:first_name, :last_name, :phone, :role
    ) }
    devise_parameter_sanitizer.for(:sign_up) { |u| u.permit(
    	:email, :password, :password_confirmation, :current_password,
    	:first_name, :last_name, :phone, :role
    ) }
  end

	######################################################################
	# Callback function to specify the layout based on the controller that
	# is in use.
	######################################################################
  def layout_by_resource
    if self.is_a?(HomeController)
    	"home"
    elsif self.is_a?(DeviseController) && !user_signed_in?
			"devise"
    else
      "admin"
    end
  end
  
  ######################################################################
  # The access_denied method is the controller method for catching
  # a CanCan exception for an unauthorized action. The user will be
  # redirected to the admin_oops_url
  ######################################################################
  def access_denied(exception)
    msg = "You are not authorized to access the requested #{exception.subject.class}."
    display_alert(message: msg, target: Oops::ADMIN)
  end
  
  
  ######################################################################
  # The missing_document method is the controller method for catching
  # a Mongoid Mongoid::Errors::DocumentNotFound exception across all
  # controller actions. User will be redirected to the groups#index view
  ######################################################################
  def missing_document(exception)
    msg = "We are unable to find the requested #{exception.klass} - ID ##{exception.params[0]}"
    display_alert(message: msg, target: Oops::ADMIN)
  end  
end
