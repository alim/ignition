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

  #####################################################################
  # The list_groups helper method will generate of list group labels
  # as an html code segment.
  #####################################################################
	def list_groups(groups)
    html = ""
    groups.each do |group|
      html = html + '<span class="label">' + group.name + '</span> &nbsp;'
    end
    html.html_safe
  end
end
