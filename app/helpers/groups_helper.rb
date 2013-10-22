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
	
	######################################################################
	# The group_list method will return a list of groups that are owned
	# by the user. If no groups are found for the user then nil will be
	# returned. The group list will return an array of hashes. Each array
	# element will contain a hash of the form:
	# 
	# group_list[0] = { id: 1, related: true, label: 'name'}
	#
	# The id: will be the group.id. The related: key will be either true
	# or false depending on whether the group is already related to the
	# resource. The label: key will hold the name of the group.
	# 
	# The method takes a parameter hash with the following keys:
	#
	# * user: The owner of the groups
	# * resource: The resource to which we want to relate the groups. This parameter will be used to see if the group is already related.
	######################################################################
	def group_list(params)
	  begin
	    owned_groups = Group.owned_groups(params[:user])
      resource = params[:resource]
      
		  @list_name = 'Available groups'  
		  group_ids = resource.group_ids
		  group_list = []
		  owned_groups.each do |group|  
		    group_list << {id: group.id, related: group_ids.include?(group.id) , 
		      label: group.name}
		  end
		  
		  return group_list	    
	    
	  rescue Mongoid::Errors::DocumentNotFound
			return nil
		end
	end
end
