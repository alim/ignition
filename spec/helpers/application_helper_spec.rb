require 'spec_helper'

describe ApplicationHelper do
  describe "#active method tests" do
    it "should return active string, if the path matches" do
      helper.request.path = admin_path
      helper.active(admin_path).should == "active"
    end

    it "if group path and settings selected, should return active" do
      helper.request.path = groups_path
      helper.active('/settings').should == "active"
    end

    it "if project path and settings selected, should return active" do
      helper.request.path = projects_path
      helper.active('/settings').should == "active"
    end

    it "if edit user path and settings selected, should return active" do
      helper.request.path = edit_user_registration_path
      helper.active('/settings').should == "active"
    end

    it "should return empty string, if the path does not match" do
      helper.request.path = 'some_path'
      helper.active(admin_path).should be_nil
    end
  end
end
