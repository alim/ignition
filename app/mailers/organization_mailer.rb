class OrganizationMailer < ActionMailer::Base

  ORGANIZATION_FROM_EMAIL = ENV["ORGANIZATION_FROM_EMAIL"].present? ?
    ENV["ORGANIZATION_FROM_EMAIL"] : "no-reply@example.com"

  ORGANIZATION_EMAIL_SUBJECT = ENV["ORGANIZATION_EMAIL_SUBJECT"].present? ?
    ENV["ORGANIZATION_EMAIL_SUBJECT"] : "Organization Membership Notification"

  default from: "#{ORGANIZATION_FROM_EMAIL}"
  default subject: "#{ORGANIZATION_EMAIL_SUBJECT}"

  ######################################################################
  # The member_email method will notify a new member of a organization
  # that he/she has been added by the organization owner.
  ######################################################################
  def member_email(user, organization)
  	# Convience varaibles for email templates
  	@organization = organization
  	@user = user
  	@password = user.password

  	begin
  		@owner = User.find(@organization.owner_id) if @organization.owner_id

  		if @user.email
  			mail(subject: "#{@owner.first_name} #{@owner.last_name} has added you to their organization.",
  				to: @user.email)
  		else
  			logger.error("[OrganizationMailer.member_email] ERROR: Unable to find User email address")
  		end
  	rescue Mongoid::Errors::DocumentNotFound
			logger.error("[OrganizationMailer.member_email] ERROR: Unable to find organization owner record")
		end

  end
end
