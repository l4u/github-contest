
require 'set'


class User
  attr_accessor :id
  attr_accessor :test
  attr_accessor :repositories
  
  attr_accessor :predicted
  
  def initialize(id)
    @id = id
    @test = false
    @repositories = Set.new 
    @predicted = Set.new 
  end
  
  def has_repo?(repository)
    @repositories.include?(repository.id)
  end
  
  def has_or_predicted_repo?(repository)
    return (@repositories.include?(repository.id) or @predicted.include?(repository.id))
  end
  
  def add_prediction(repository)
    @predicted.add(repository.id)
  end
  
  def get_prediction_string
    return "#{@id}:" if @predicted.empty?
    return "#{@id}:#{@predicted.to_a.join(",")}"
  end
  
end