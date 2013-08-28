module GroupsHelper

	######################################################################
	# The get_owner is a view helper method that will return either the
	# email address of the group owner or "None".
	######################################################################
	def get_owner_email(group)
		begin 
			return User.find(group.owner_id).email
		rescue Mongoid::Errors::DocumentNotFound
			return "None"
		end
	end
end
