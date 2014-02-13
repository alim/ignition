require 'spec_helper'

describe "Sign up for new account" do 
  it "should have a sign up page" do
    visit new_user_registration_url
    page.has_content?('Sign Up')
  end
end