class Ability
  include CanCan::Ability

  def initialize(user)
# puts "[Ability] user.id = #{user.id}"
  	# Check to see if we can get the role attribute
  	if !user.nil?
			if user.role == User::SERVICE_ADMIN
				can :manage, :all
			end

			# Only allow customer to manager their own records or records
			# that belong to part of their group.
			if user.role == User::CUSTOMER
			
        can :manage, Group, owner_id: user.id
        
#				can :manage, Group do |group|
#					true if group.owner_id == user.id
#				end
  
				can [:new, :create, :edit, :update, :destroy], Account do |account|
				  true if account.user.id == user.id
				end
				
				can [:show, :edit, :update], User, id: user.id
				
#				can [:show, :edit, :update], User do |a_user|
#  puts "[Ability] a_user.id=#{a_user.id} and user.id=#{user.id}"				
#				  true if a_user.id == user.id
#				end
				
#				can :manage, Attendee do |attendee|
#					check_ids(attendee, user)
#				end 

				
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

#		if resource.user_id == user.id
#			return true
#		else
#			rgids = resource.groups.pluck(:id)
#			ugids = user.groups.pluck(:id)
# 
#			# Check to see if the intersection of resource-group id's and
#			# user-group id's is empty. If it is empty, then resource and user
#			# do not belong to common groups.
#			return !(rgids & ugids).empty?
#		end 
  end
  
end
