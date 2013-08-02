class HomeController < ApplicationController

	
  def index
  	@home_active="active"
  end

  def contact
  	@contact_active="active"
  end

  def support 
  	@support_active="active"
  end
  
  def about
  	@about_active="active"
  end

end
