class Group
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :name, type: String
  field :description, type: String
  field :owner_id, type: Moped::BSON::ObjectId
  
  # Relationship items
  has_and_belongs_to_many :users
end
