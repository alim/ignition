class AdminController < ApplicationController
	before_filter :authenticate_user!
	
	def index
	end
	
	def oops
	end
	
end
