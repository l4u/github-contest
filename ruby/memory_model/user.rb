
class User
  attr_accessor :id
  attr_accessor :repositories
  
  def initialize(id)
    @id = id
    @repositories = Hash.new    
  end
  
end