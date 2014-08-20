#######################################################################
# The Organizational concern's purpose is to add features associated
# with working with the Organizational model to class that belong
# to an organization.
#######################################################################
module Organizational
  extend ActiveSupport::Concern

  included do
    # Returns records with matching organization or user id's
    scope :org_or_user, ->(user){any_of(
      {organization_id: user.organization_id},
      {user_id: user.id}
    )}

    scope :organization, ->(org){where(oganization_id: org.id)}
    scope :user, ->(user){where(user_id: user.id)}
  end

  ## CLASS METHODS ----------------------------------------------------

  module ClassMethods

    ###################################################################
    # Returns all records that are either owned by the user or is
    # managed by the organization that the user belongs to.
    ###################################################################
    def in_organization(user)
      if user && user.organization
        self.org_or_user(user)
      elsif user
        self.user(user)
      else
        self.organization(user.organization)
      end
    end

  end

  ## INSTANCE METHODS -------------------------------------------------

  ######################################################################
  # Relate the current class to it's organization, if it is present for
  # the class.
  ######################################################################
  def relate_to_organization
    if self.respond_to?(:user)
      if (org = self.user.organization)
        org.send(self.class.to_s.downcase.pluralize) << self
      end
    end
  end

end
