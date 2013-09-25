class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  
  layout :layout_by_resource

	before_filter :configure_permitted_parameters, if: :devise_controller?

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
end
