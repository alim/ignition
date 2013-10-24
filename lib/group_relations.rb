########################################################################
# The GroupRelations module provides utility methods for handling 
# relationships between resources and user groups. The module is
# designed to be injected into service resources and to the group
# model and controller objects.
########################################################################
module GroupRelations

  ######################################################################
  # The relate_groups method will relate a series of user groups to 
  # a given resource. The method takes a parameter hash with the 
  # following parameter key-values:
  #
  # * group_ids: is an array of group id's to relate to the resource
  # * resource: is the resource to which the groups will be related
  #
  # The method assumes that the relationship is either 1 (resource) -
  # N (groups) or N (groups) - N (projects).
  ######################################################################
  def relate_groups(params)
    group_ids = params[:group_ids]
    resource = params[:resource]
    
    # Clear the relation
    resource.groups = nil

    if group_ids.present?
      group_ids.each do |id|
        group = Group.find(id)
        resource.groups << group
      end

      return true
    else
      return nil
    end
  end
  
	######################################################################
	# The relate_resources method will relate the requested resources to 
	# the group. It is expecting an parameter hash with the following
	# key/value pairs:
	#
	# * resource_ids: array of resource id's. It will then add each resource to the group.
	# * group: Group object to which the resource will be related
	# * class: Text string of the name of the resource model Class (see group.rb)
  #
	######################################################################  
  def relate_resources(params)
    resource_ids = params[:resource_ids]
    group = params[:group]
    resource_class = params[:class]
    
    # Clear the relations by constructing the call from passed in
    # variables. A call translation example for a class passed
    # in that is 'Project', would result in a method invocation 
    # group.projects = nil
    group.send(resource_class.downcase.pluralize + '=', nil)
    
    if resource_ids.present?
      resource_ids.each do |rid|
        resource = Object.const_get(resource_class).find(rid)
        group.send(resource_class.downcase.pluralize) << resource
      end
      
      return true
    else
      return nil
    end
  end
  
end
