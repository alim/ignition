module UsersHelper
	def list_groups(groups)
    html = ""
    groups.each do |group|
      html = html + '<span class="label">' + group.name + '</span> &nbsp;'
    end
    html.html_safe
  end
end
