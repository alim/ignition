module ApplicationHelper

  #####################################################################
  # A little helper method to display the page title. To use the
  # method:
  #     <% title "your title here" %>
  #####################################################################
  def title(page_title)
    content_for(:title) { page_title }
  end

  #####################################################################
  # The active method is a helper function that returns "active" or
  # empty string. It is used to set a CSS class to active for
  # highlighting the active menu item.
  #####################################################################
  def active(path)
    if (path == home_index_path && request.fullpath == '/') ||
       (path == '/settings' && (request.fullpath =~ /^\/group/).present?) ||
       (path == '/settings' && (request.fullpath =~ /^\/project/).present?) ||
       (path == '/settings' && (request.fullpath =~ /^\/auth\/users\/edit/).present?) ||
        request.fullpath == path
      "class=active"
    end
  end

  ######################################################################
  # The selection_options method generates a selection list array based
  # on a hash that is pasted as the single parameter. The hash will
  # use the key as the label and value as the id.
  ######################################################################
  def selection_options(selection_hash)
    options = []
    selection_hash.each do |label, id|
      options << [label, id]
    end
    return options
  end
end
