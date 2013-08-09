########################################################################
# The Oops module provides utility methods for handling redirection
# to an error page. The module can be used as a mixin by including it
# in the appropriate controllers. The module makes a couple of
# routing assumptions. They include:
# 
# * home_oops_url - is the path to the public facing error page.
# * admin_oops_url - is the path to the private facing error page.
#
# The module will set flash variables, so it assumes the error pages
# have the capability of display flash error and alert messages
########################################################################
module Oops

	## Constants for targeting the alert message to either the home or
	## admin controller.
	HOME = 1
	ADMIN = 2

  ######################################################################
  # The display_alert method will display an alert message to an error
  # page. It takes a hash as an argument, that includes:
  # * message - the message to display
  # * target - the target error page - Oops::ADMIN or Oops::HOME
  # * resource - the resource that can contain the error messages
  ######################################################################
  def display_alert(args)
  	if args.count >= 2
			msg = args[:message]
			target = args[:target]
			resource = args[:resource]
			
			respond_to do |format|
				if target == ADMIN
					format.html { redirect_to admin_oops_url, alert: msg }
				else
					format.html { redirect_to home_oops_url, alert: msg }
				end
				
		  	format.json { render json: resource.errors, 
		  		status: :unprocessable_entity } if resource.present?
		  end
    else
    	return nil
    end
  end
  
  ######################################################################
  # The display_error method will display an error message to an error
  # page. It takes a hash as an argument, that includes:
  # * message - the message to display
  # * target - the target error page - Oops::ADMIN or Oops::HOME
  # * resource - the resource that can contain the error messages
  ######################################################################
  def display_error(msg)
  	if args.count >= 2
			msg = args[:message]
			target = args[:target]
			resource = args[:resource]
			
			respond_to do |format|
				flash[:error] = msg
				
				if target == ADMIN
					format.html { redirect_to admin_oops_url }
				else
					format.html { redirect_to home_oops_url, alert: msg }
				end
				
		  	format.json { render json: @group.errors, 
		  		status: :unprocessable_entity } if resource.present?
		  end
    else
    	return nil
    end		  
  end
end
