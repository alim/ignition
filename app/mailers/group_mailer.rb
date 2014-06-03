class GroupMailer < ActionMailer::Base

  GROUP_FROM_EMAIL = ENV["GROUP_FROM_EMAIL"].present? ?
    ENV["GROUP_FROM_EMAIL"] : "no-reply@example.com"

  GROUP_EMAIL_SUBJECT = ENV["GROUP_EMAIL_SUBJECT"].present? ?
    ENV["GROUP_EMAIL_SUBJECT"] : "Group Membership Notification"

  default from: "#{GROUP_FROM_EMAIL}"
  default subject: "#{GROUP_EMAIL_SUBJECT}"

  ######################################################################
  # The member_email method will notify a new member of a group
  # that he/she has been added by the group owner.
  ######################################################################
  def member_email(user, group)
  	# Convience varaibles for email templates
  	@group = group
  	@user = user
  	@password = user.password

  	begin
  		@owner = User.find(@group.owner_id) if @group.owner_id

  		if @user.email
  			mail(subject: "#{@owner.first_name} #{@owner.last_name} has added you to their group.",
  				to: @user.email)
  		else
  			logger.error("[GroupMailer.member_email] ERROR: Unable to find User email address")
  		end
  	rescue Mongoid::Errors::DocumentNotFound
			logger.error("[GroupMailer.member_email] ERROR: Unable to find Group owner record")
		end

  end
end
