class AdminController < ApplicationController
	before_filter :authenticate_user!

	layout 'admin'

	######################################################################
	# The index action presents the dashboard or main landing page after
	# logging into the service.
	######################################################################
	def index
  end

	######################################################################
	# Error action and view to display errors to the user.
	######################################################################
	def oops
	end

	######################################################################
	# Password_reset presents the password reset page.
	######################################################################
	def password_reset
	end

	######################################################################
	# The help function will present a help page for the service.
	######################################################################
	def help
	end

end
