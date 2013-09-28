class Group
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :name, type: String
  field :description, type: String
  field :owner_id, type: Moped::BSON::ObjectId
  
  # Relationship items
  has_and_belongs_to_many :users
  
  # Validations
  validate :members_list
  validates_presence_of :name
  
  ## PUBLIC INSTANCE METHODS -------------------------------------------
  
  # VIRTUAL ATTRIBUTE METHDS
  ######################################################################
  # The members and the members= are methods for creating virtual 
  # attributes that are not stored in the database. These virtual
  # attributes will hold a membership list in the form of a list of
  # individual email address.
  ######################################################################
  def members
    @members
  end
  
  def members=(value)
    @members=value
  end
  
  ## PROTECTED INSTANCE METHODS ----------------------------------------
    
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
end
