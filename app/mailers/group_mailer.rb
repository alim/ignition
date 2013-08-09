class GroupMailer < ActionMailer::Base
  default from: "no-reply@example.com"
  default subject: "Group Membership Notification"
  
  ######################################################################
  # The member_email method will notify a new member of a group
  # that he/she has been added by the group owner.
  ######################################################################
  def member_email(user, password, group)
  
  	# Convience varaibles for email templates
  	@group = group
  	@user = user
  	@password = password
  	
  	begin
  		@owner = User.find(group.owner_id) if group.owner_id
  		
  		if @user.email
  			mail(subject: "#{@owner.first_name} #{@owner.last_name} has added you to their group.",
  				to: @user.email)
  		else
  			logger.error("[GroupMailer.member_email] ERROR: Unable to find User email address")
  		end
  	rescue ActiveRecord::RecordNotFound
			logger.error("[GroupMailer.member_email] ERROR: Unable to Group owner record")
		end
  	
  end
end
