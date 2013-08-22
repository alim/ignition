class AdminController < ApplicationController
	before_filter :authenticate_user!
	
        layout 'admin' 

	def index

         admin_active="active"
        
        end

	def oops
	end

        def password_reset

         @password_reset_admin_active="active"

        end

        def help

         @help_admin_active="active"

        end

       
	
end
