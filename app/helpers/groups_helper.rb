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

  ######################################################################
	# The resource_list method will set an instance variable called 
	# @resources to hold an array of hashes. Each array element holds
	# resource information in a hash. The user can select multiple 
	# resources to share with the group. This instance variable is used 
	# by the form partial. The example array of hash values are
	# shown below:
	#
	# @resources[0] = { id: 1, related: true, label: 'name'} 
	#
	# The 'related' key/value is used to indicae whether the resource 
	# is already related to the group. Its value can either be true or 
	# false. The 'label' key/value is text choice that will be displayed
	# to the user.
	#
	# This method takes a parameter hash with the following key/value
	# pairs
	# * class: A text value with the name of the resource class to list
	# * group: The group object to which we want to relate the resource
	# * user_id: The user_id to which the resource and group should belong
	#
	# You will need to customize this method to list the resources that
	# you want to share with the group.
	######################################################################
	def resource_list(params)
	  rclass = params[:class]
	  user_id = params[:user_id]
	  group = params[:group]
	  
	  @list_name = "Available #{rclass.capitalize.pluralize}"
	  begin
	    resources = Object.const_get(rclass).where(user_id: user_id)

	    # Get list of resource ids assoicated with the group
	    # We construct the call to specify the resource class using
	    # the send and Object.const_get methods.
	    related_resource_ids = group.send(
	      Object.const_get(rclass).to_s.downcase + '_ids')

	    resource_list = []
	    resources.each do |resource|
	      resource_label = resource.respond_to?(:name) ? resource.name : resource.id.to_s
	      
	      resource_list << {id: resource.id, 
	        related: related_resource_ids.include?(resource.id),
	        label: resource_label }
	    end

	    return resource_list
	    
	  rescue Mongoid::Errors::DocumentNotFound
			return nil
	  end
	end  
end
