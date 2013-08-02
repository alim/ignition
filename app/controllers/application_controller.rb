class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  
  layout :layout_by_resource

	def after_sign_in_path_for(resource)
		admin_url
	end
	
	def after_sign_out_path_for(resource)
		root_url
	end	

  protected

	######################################################################
	# Callback function to specify the layout based on the controller that
	# is in use.
	######################################################################
  def layout_by_resource
    if self.is_a?(AdminController)
    	"admin"
    else
      "home"
    end
  end
end
