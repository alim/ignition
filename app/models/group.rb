########################################################################
# The Group class allows us to authorize a group of users to access
# a primary resource, such as a Project. Group access to a primary
# resource enables the group to access all records related to the
# primary resource.
########################################################################
class Group
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :description, type: String
  field :owner_id, type: BSON::ObjectId

  attr_accessor :members

  ## RELATIONSHIPS -----------------------------------------------------

  has_and_belongs_to_many :users

  # Sample primary resource relation. We are using a resource that
  # represents a Project in our service. We also set a class constant
  # to the name of the class to which the groups will be given access

  has_and_belongs_to_many :projects
  RESOURCE_CLASS = 'Project'

  ## VALIDATIONS -------------------------------------------------------

  validate :members_list
  validates_presence_of :name
  validates_presence_of :description
  validates_presence_of :owner_id

  ## SCOPE DEFINITIONS -------------------------------------------------

  scope :owned_groups, ->(owner){
    owner.present? ? where(owner_id: owner.id) : scoped
  }


  ## PUBLIC INSTANCE METHODS -------------------------------------------

  ######################################################################
  # The members_list method will parse the membership list of email
  # addresses check them for valid email format.
  ######################################################################
  def members_list
    if self.members.present?
      email_list = self.members.split
      email_list.each do |email|
        if !email.match(/^.+@.+\..+/)
          self.errors.add(:members, "invalid email address - #{email}")
        end
      end
    end
  end

  ######################################################################
  # The create_notify method will look to see if members have been assigned
  # to the Group. For each email address that has nil user record, this
  # method will create a new User record for the requested member. The
  # new user will be notified of their new account. Each newly created
  # user will be associated with the current group.
  ######################################################################
  def create_notify
    member_list = lookup_users
    if member_list.present?
      plen = 12

      member_list.each do |member, user|
        if user.nil?
          # Create a new user
          new_password = Devise.friendly_token.first(plen)
          user = User.create!(first_name: '*None*', last_name: '*None*',
            role: User::CUSTOMER, email: member.dup, password: new_password,
            password_confirmation: new_password, phone: '888.555.1212')
        end

        self.users << user
        GroupMailer.member_email(user, self).deliver
      end
    end
  end

  ######################################################################
  # The invite_member method will resend an membership notification
  # to an existing member. If the member has not ever logged into the
  # service the member will be sent a new password.
  #
  # * user - User object to notify
  ######################################################################
  def invite_member(user)
    plen = 12

    if user.sign_in_count == 0
      user.password = user.password_confirmation = Devise.friendly_token.first(plen)

      if user.save
        GroupMailer.member_email(user, self).deliver
      else
        return false
      end
    else
      # Notify current user that they are now a member of the group
      GroupMailer.member_email(user, self).deliver
    end
  end


  ######################################################################
  # The lookup_user method will take an string of white-space separated
  # email addresses and return a hash based on the email addresses
  # as keys. The value of the hash will be a User or nil, depending on
  # whether the email address indicates a current user. The method will
  # return HASH, if it can successfully process all user email addresses
  # or nil if it cannot. The method will check for valid email
  # address format, while processing. The method also takes the Group
  # record as the parameter. It assumes that group.members holds the
  # email list.
  ######################################################################
  def lookup_users
    users = {}     # Hash for returning results

    if members.present?
      elist = members.split

      # Look for a current user
      elist.each do |email|
        if (user = User.where(email: email).first).present?
          users[email] = user
        else
          users[email] = nil
        end
      end
    end
    users
  end


  ######################################################################
  # The remove_member method will remove selected group members
  # The parameter is a list of group members that represents an array,
  # which includes user ID's of the members to disassociate from the
  # group
  ######################################################################
  def remove_members(members)
    if members.present?
      members.each do |uid|
        user = User.find(uid)
        self.users.delete(user)
      end
      self.reload
    end
  end

end
