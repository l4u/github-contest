
class User
  attr_accessor :id
  attr_accessor :test
  attr_accessor :repositories
  
  attr_accessor :predicted
  
  def initialize(id)
    @id = id
    @test = false
    @repositories = Hash.new 
    @predicted = Hash.new 
  end
  
  def has_repo?(repository)
    return !@repositories[repository.id].nil?
  end
  
  def has_or_predicted_repo?(repository)
    return (!@repositories[repository.id].nil? or !@predicted[repository.id].nil?)
  end
  
  def add_prediction(repository)
    @predicted[repository.id] = repository
  end
  
  def get_prediction_string
    return "#{@id}:" if @predicted.nil? or @predicted.empty?
    return "#{@id}:#{@predicted.keys.join(",")}"
  end
  
end