module UsersHelper

  #####################################################################
  # The user_search_options method returns an options_for_select
  # grouping for searching users by email, first name, or last name
  #####################################################################
  def user_search_options
    return options_for_select([
      ['Email', 'email'],
      ['First name', 'first_name'],
      ['Last name', 'last_name']
    ])
  end

end
