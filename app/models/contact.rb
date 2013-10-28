#######################################################################
# This model is used to hold the contact request. It is not tied to
# a database table, but just holds the contents in memory. We do include
# ActiveModel validations to help validate the form entries.
#######################################################################
class Contact
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming

	# Email address defaults for all contact requests
	CONTACT_EMAILBOX = ENV["CONTACT_EMAILBOX"].present? ? 
	  ENV["CONTACT_EMAILBOX"] : 'support@example.com'
	  
  CONTACT_FROM = ENV["CONTACT_FROM"].present? ? 
	  ENV["CONTACT_FROM"] : 'no-reply@example.com'
  
  CONTACT_SUBJECT = ENV["CONTACT_SUBJECT"].present? ? 
	  ENV["CONTACT_SUBJECT"] : 'New contact request'
  
	# ACCESSORS ---------------------------------------------------------
  attr_accessor :name, :email, :phone, :body

	# VALIDATIONS -------------------------------------------------------
  validates :name, :email, :body, :presence => true
  validates :email, :format => { :with => %r{.+@.+\..+} }, :allow_blank => true
  
  # INSTANCE METHODS --------------------------------------------------
  
  def initialize(attributes = {})
    attributes.each do |name, value|
      send("#{name}=", value)
    end
  end

  def persisted?
    false
  end
  
end
