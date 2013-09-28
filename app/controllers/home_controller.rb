########################################################################
# The HomeController is responsible for presenting the public interface
# to the web service. Most web services will have a public facing site
# that presents the customer with a series of pages that describe the
# the service and gives them access to public information. This 
# controller is designed to support this feature.
########################################################################
class HomeController < ApplicationController

  ######################################################################
  # The index action will present the user with the primary landing
  # page for the service.
  ######################################################################
  def index
  	@home_active="active"
  end

  ######################################################################
  # The contact action will present a contact form and email a copy of
  # the contents to the configured address. See the corresponding the
  # application.yml for configuring the contact reply_to address.
  ######################################################################
  def contact
  	@contact_active="active"
  end

  ######################################################################
  # The support acction will present a support page to the customer.
  ######################################################################
  def support 
  	@support_active="active"
  end
  
  ######################################################################
  # The about page will present a page for telling the customer about
  # your web service or company.
  ######################################################################
  def about
  	@about_active="active"
  end

end
