########################################################################
# The contact mailer is for managing the contact form  request on
# the web service.
########################################################################
class ContactMailer < ActionMailer::Base
  default from: Contact::CONTACT_FROM
  default to: Contact::CONTACT_EMAILBOX
  
  ######################################################################
  # The standard contact request message.
  ######################################################################
	def contact_message(contact)
		# Setup instance variable for mailer view
		@contact = contact
		
		mail(:subject => "#{Contact::CONTACT_SUBJECT}")
	end  
end
