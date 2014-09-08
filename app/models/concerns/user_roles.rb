module UserRoles
  extend ActiveSupport::Concern

  included do
    scope :by_email, ->(email){ where(email: /^.*#{email}.*/i) }
    scope :by_first_name, ->(name){ where(first_name: /^.*#{name}.*/i) }
    scope :by_last_name, ->(name){ where(last_name: /^.*#{name}.*/i) }
    scope :by_role, ->(role){ where(role: role) }
  end

  ## PUBLIC INSTANCE METHODS -------------------------------------------

  ######################################################################
  # The role_str returns the string representation of the role assigned
  # to the user.
  ######################################################################
  def role_str
    case self.role
    when User::CUSTOMER
      "Customer"
    when User::SERVICE_ADMIN
      "Service Administrator"
    else
      "Unknown"
    end
  end

  #####################################################################
  # Returns true or false if user has admin role.
  #####################################################################
  def admin?
    role == User::SERVICE_ADMIN
  end

  #####################################################################
  # Returns true or false if user has customer role.
  #####################################################################
  def customer?
    role == User::CUSTOMER
  end

end
