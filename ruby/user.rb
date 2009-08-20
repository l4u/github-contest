
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
    return @repositories.include?(repo_id.to_s)
  end
  
  def has_predicted?(repo_id)
    return  @predicted.include?(repo_id.to_s)
  end
  
  def has_or_predicted_repo?(repository)
    return (has_repo?(repository.id) or has_predicted?(repository.id))
  end
  
  def add_prediction(repo_id)
    raise "user=#{@id} cannot add predicted repo id #{repo_id}, already in predicted set" if has_predicted?(repo_id)
    raise "user=#{@id} cannot add predicted repo id #{repo_id}, already in use set #{@repositories.to_a.join(",")}" if has_repo?(repo_id)
    @predicted.add(repo_id.to_s)
  end
  
  def add_repo(repo_id)
    raise "user=#{@id} cannot add repo id #{repo_id}, already in in use " if has_repo?(repo_id)
    @repositories.add(repo_id.to_s)
  end
  
  def get_prediction_string
    return "#{@id}:" if @predicted.empty?
    return "#{@id}:#{@predicted.to_a.join(",")}"
  end
  
end