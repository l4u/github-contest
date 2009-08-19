
require 'set'


class User
  # integer user id
  attr_accessor :id
  # boolean of whether the user is a test user or not
  attr_accessor :test  
  # set of repo id's
  attr_accessor :repositories
  # set of repo id's
  attr_accessor :predicted
    
  def initialize(id)
    @id = id
    @test = false
    @repositories = Set.new 
    @predicted = Set.new 
  end
  
  def has_repo?(repo_id)
    @repositories.include?(repo_id)
  end
  
  def has_or_predicted_repo?(repository)
    return (@repositories.include?(repository.id) or @predicted.include?(repository.id))
  end
  
  def add_prediction(repo_id)
    raise "cannot add predicted repo id #{repo_id}, already in predicted set" if @predicted.include?(repo_id)
    @predicted.add(repo_id)
  end
  
  def get_prediction_string
    return "#{@id}:" if @predicted.empty?
    return "#{@id}:#{@predicted.to_a.join(",")}"
  end
  
end