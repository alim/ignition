########################################################################
# The SharedInstanceMethods module is used for storing methods that will be
# accross multiple Rails model classes. To use these methods, you will
# need to:
#
#    include SharedInstanceMethods
#
# in your model class definition
########################################################################
module SharedInstanceMethods

  ######################################################################
  # The attribute_str method is a utility instance method that is used
  # to print the human readable string associated with an attribute
  # value. It takes two parameters as follows:
  #
  # * ahash - is a hash that stores possible values for an attribute the key is assumed to be the label
  # * value - is the value of the attribute that is stored in the object.
  ######################################################################
  def attribute_str(ahash, value)
    str = 'Unknown'

    if ahash.present? & value.present?
      ahash.each do |label, hash_value|
        if hash_value == value
          str = label
          break
        end
      end
    end
    return str
  end
end
