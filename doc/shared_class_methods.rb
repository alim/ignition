########################################################################
# The SharedMethods module is used for storing methods that will be
# accross multiple Rails model classes. To use these methods, you will
# need to:
#
#    extend SharedMethods
#
# in your model class definition
########################################################################
module SharedClassMethods

  ######################################################################
  # The find_with_groups class scope method will return all resource
  # records that have a group in common with the User that is passed
  # in as a parameter. The algorithm for determining whether the
  # resource can be accessed is as follows:
  #
  # 1. Identify any groups that the user is associated with
  # 2. Identify the list of resoruces that are owned by the user.
  # 3. For each group of which the user is a member, we will pluck the project id's
  # 4. For each project, we will then pluck the resource id's
  # 5. We then look for only the unique resource id's
  # 6. The ID's are then sorted
  ######################################################################
  def find_with_groups(user)
    begin
      # Find all group ids associated with User
      groups = User.find(user.id).groups

      if groups.present?

        # Find all the resource id's associated with the user
        ids = []
        ids = user.send(self.to_s.underscore.pluralize).pluck(:id)

        # For each group associated with the user locate the associated
        # project resources
        groups.each do |group|
          projects = group.projects

          projects.each do |project|
            ids += project.send(self.to_s.underscore.pluralize).pluck(:id)
          end
        end

        ids.uniq!
        ids.sort!

        where(:id.in => ids)
      else
        where(user_id: user.id)
      end
    rescue  ActiveRecord::RecordNotFound
      logger.error("[#{self}.find_with_groups] Could not find user - user ID: #{user.id}")
      scoped
    end
  end
end
