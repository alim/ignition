class UserMailer < ActionMailer::Base
  default from: "some_email@example.com"

  ######################################################################
  # Email for new user account. It will email the user their login,
  # password, a login link, and a link to change their password.
  ######################################################################
  def new_account(user)
    @user = user
    @login_url =  new_user_session_url
    @new_password_url =  edit_user_password_url

    mail(to: @user.email, subject: 'New Account')
  end
end
