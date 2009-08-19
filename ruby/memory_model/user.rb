
class User
  attr_accessor :id
  attr_accessor :test
  attr_accessor :repositories
  
  def initialize(id)
    @id = id
    @test = false
    @repositories = Hash.new    
  end
  
end