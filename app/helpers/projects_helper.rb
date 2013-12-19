module ProjectsHelper

  ######################################################################
  # The project_list method will return a list of projects that are
  # accessible by the user. If no projects are found for the user
  # then nil will be returned. The method takes a parameter:
  #
  # * user: The owner of the projects
  #
  # The method also sets a variable called list_name that is returned
  # as the second return value. This variable can be used in view as a
  # label for the selection list.
  ######################################################################
  def project_list(user)
    begin
      owned_projects = Project.find_with_groups(user)
      list_name = 'Available Projects'

      return owned_projects, list_name

    rescue Mongoid::Errors::DocumentNotFound
      return nil
    end
  end
end
