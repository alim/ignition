########################################################################
# The HomeController is responsible for presenting the public interface
# to the web service. Most web services will have a public facing site
# that presents the customer with a series of pages that describe the
# the service and gives them access to public information. This
# controller is designed to support this feature.
########################################################################
class HomeController < ApplicationController

  ######################################################################
  # The index action will present the user with the primary landing
  # page for the service.
  ######################################################################
  def index
  end


	# CONTACT METHODS ---------------------------------------------------

	#####################################################################
	# The contact method presents a form for contacting us. The form
	# then calls the create_contact method for sending us the email.
	#####################################################################
  def contact
  	@contact = Contact.new
  end

  #####################################################################
  # The create_contact method uses a mailer class to generate an email
  # message to us via our website.
  #####################################################################
  def create_contact
		@contact = Contact.new(params[:contact])

		if @contact.valid?
		  begin
			  ContactMailer.contact_message(@contact).deliver

        redirect_to(home_contact_url, notice:
          "Contact request was successfully submitted.")

      rescue Timeout::Error, Net::SMTP, Net::SMTPAuthenticationError,
        Net::SMTPServerBusy, Net::SMTPSyntaxError, Net::SMTPFatalError,
        Net::SMTPUnknownError => e
        logger.error("Unable to send email to: #{@contact.email} - error = #{e}")
        flash[:alert] = "Contact delivery error sending email - #{e.message}"
        redirect_to home_contact_url
      end

		else
			# Create a hash that holds the request options
			@verrors = @contact.errors.full_messages
			render action: "contact"
		end
  end

  ## -------------------------------------------------------------------

  ######################################################################
  # The support action will present a support page to the customer.
  ######################################################################
  def support
  end

  ######################################################################
  # The about page will present a page for telling the customer about
  # your web service or company.
  ######################################################################
  def about
  end

end
