require 'spec_helper'

describe "Sign up for new account" do 
  let(:sign_up_page) {
    visit new_user_registration_url
  }

  let(:sign_up_fields) {
    fill_in 'First name', with: 'Andy'
    fill_in 'Last name', with: 'Lim'
    fill_in 'Email', with: 'andylim61@gmail.com'
    fill_in 'Phone', with: '734.555.1212'
  }

  it "should have a sign up page" do
    sign_up_page
    page.has_content?('Sign Up')
  end

  it "should allow us to enter sign up information" do
    sign_up_page
    sign_up_fields
    fill_in 'Password', with: 'test1234'
    fill_in 'Password confirmation', with: 'test1234'
    click_button 'Sign Up'
    page.has_content?('Success')
  end

  it "should not allow too short password" do
    sign_up_page
    sign_up_fields
    fill_in 'Password', with: 'test'
    fill_in 'Password confirmation', with: 'test'
    click_button 'Sign Up'   
    page.has_content?('Error') 
  end
end