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
    return nil if args.count < 2
    flash[:alert] = args[:message]
    display_message(args[:target])
  end

  ######################################################################
  # The display_error method will display an error message to an error
  # page. It takes a hash as an argument, that includes:
  # * message - the message to display
  # * target - the target error page - Oops::ADMIN or Oops::HOME
  # * resource - the resource that can contain the error messages
  ######################################################################
  def display_error(args)
  	return nil if args.count < 2
    flash[:error] = args[:message]
    display_message(args[:target])
  end

  ######################################################################
  # Display an error message on the correct layout.
  ######################################################################
  def display_message(target)
    if target == ADMIN
      redirect_to admin_oops_url
    else
      redirect_to home_oops_url
    end
  end

end
