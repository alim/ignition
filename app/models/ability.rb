class Ability
  include CanCan::Ability

  def initialize(user)
    alias_action :create, :read, :update, :destroy, :to => :crud

  	# Check to see if we can get the role attribute
  	if !user.nil?

      # The service administrator should have access to all resources
			if user.role == User::SERVICE_ADMIN
				can :manage, :all
			end

			# Only allow customer to manager their own records or records
			# that belong to part of their group.
			if user.role == User::CUSTOMER

        can :crud, Account, user: {id: user.id}

        can :crud, Organization, owner_id: user.id

				can [:show, :edit, :update], User, id: user.id

				can :crud, Project do |project|
					project.organization_id == user.organization_id ||
          project.user_id == user.id
				end

			end
		end
  end

  # PROTECTED INSTANCE METHODS -----------------------------------------
  protected

  ######################################################################
  # The check_ids method will look for group id's associated with both
  # the user and the resource. If they have group id's in common, then
  # the user has access to the resource. If they do not have any group
  # id's in common, then they should not be given access to the resource.
  # The method returns true, if they should have access, otherwise it
  # returns false. The check_ids method takes two parameters:
  #
  # * resource - the object to which access is being requested
  # * user - the user object to which access would be granted
  ######################################################################
  def check_ids(resource, user)
		if resource.user.id == user.id
			return true
		else
			rgids = resource.groups.pluck(:id)
			ugids = user.groups.pluck(:id)

			# Check to see if the intersection of resource-group id's and
			# user-group id's is empty. If it is empty, then resource and user
			# do not belong to common groups.
			return !(rgids & ugids).empty?
		end
  end

end
