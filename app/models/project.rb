########################################################################
# The Project model class represents an example primary resource for the
# service. This model could be substituted with any primary resource
# that makes sense for your service. A primary resource is related to
# other resources in your system, to a user that created it, and to
# a group that can access it.
# 
# The concept of a primary resource allows you to grant group access to
# the primary resource and any of its related resources.
########################################################################
class Project
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Paperclip

  # Add call to strip leading and trailing white spaces from all atributes
  strip_attributes  # See strip_attributes for more information

  field :name, type: String
  field :description, type: String

  
  ## VALIDATIONS -------------------------------------------------------
  
  validates_presence_of :name
  validates_presence_of :description
  validates_presence_of :user_id
  
  ## RELATIONSHIPS -----------------------------------------------------
  
  belongs_to :user
  has_and_belongs_to_many :groups
  has_mongoid_attached_file :charter_doc
  
  ## GROUP METHOD INJECTION --------------------------------------------
  
  include GroupRelations
  
  ######################################################################
  # The GroupRelations module has some utility methods that will enable
  # the project to interact with user groups. The group_relate method
  # uses the relate_groups utility method to relate groups to the
  # the current instance of the Project model class.
  ######################################################################
  def group_relate(group_ids)
    relate_groups(group_ids: group_ids, resource: self)
  end

end
