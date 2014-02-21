require 'spec_helper'

describe UsersHelper do
	include_context 'group_setup'

  describe "list_groups" do
  	let(:groups) { Group.all }
  	before(:each){ single_group_with_users }

  	it "should generate an HTML list of group labels" do
  		labels = ""
  		groups.each { |group| labels = labels + '<span class="label">' + group.name + '</span> &nbsp;'}
  		list_groups(groups).should eq(labels)
  	end
  end
end
