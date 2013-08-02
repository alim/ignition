class HomeController < ApplicationController
	layout 'home'
	
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

  def signup
        @signup_active="active"
  end

  def signin
        @signin_active="active"
  end

  def password_reset
        @password_reset_active="active"
  end

  def logout
        @logout_active="active"
  end
end
