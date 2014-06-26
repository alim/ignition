module Organizational
  extend ActiveSupport::Concern

  included do
    # Returns records with matching organization or user id's
    scope :in_organization, ->(user){where($or => [
      {organization_id: user.organization_id},
      {user_id: user.id}
    ])}
  end
end
