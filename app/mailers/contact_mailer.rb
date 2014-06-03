########################################################################
# The contact mailer is for managing the contact form  request on
# the web service.
########################################################################
class ContactMailer < ActionMailer::Base
	# Email address defaults for all contact requests

	CONTACT_EMAILBOX = ENV["CONTACT_EMAILBOX"].present? ?
	  ENV["CONTACT_EMAILBOX"] : 'support@example.com'

  CONTACT_FROM = ENV["CONTACT_FROM"].present? ?
	  ENV["CONTACT_FROM"] : 'no-reply@example.com'

  CONTACT_SUBJECT = ENV["CONTACT_SUBJECT"].present? ?
	  ENV["CONTACT_SUBJECT"] : 'New contact request'


  default from: CONTACT_FROM
  default to: CONTACT_EMAILBOX

  ######################################################################
  # The standard contact request message.
  ######################################################################
	def contact_message(contact)
		# Setup instance variable for mailer view
		@contact = contact

		mail(:subject => "#{CONTACT_SUBJECT}")
	end
end
