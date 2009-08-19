
# 
#  Name: k-nearest neighbour strategy
#  Description: calculate user neighbourhoods and suggest based on highest ranked missing repos
# 

require 'model'

STRATEGY_NAME = "kNN"
K = 5


# returns a set of K users in the users neighbourhood
def calculate_neighbours(user)
  return nil
end

# returns a list of unique repos ordered by neighbourhood occurance decending 
def rank_missing_repos(user, neighbours)
  return nil if neighbours.nil? or neighbours.empty?
  # build a histogram of repo occurance
  occurance_histogram = Hasn.new
  neigbours.each do |neighbour|
    neighbour.repositories.each do |repo_id|
      # ensure user does not have it already
      next if user.has_repo?(repo_id)
      # create as needed
      occurance_histogram[repo_id] = 0 if !occurance_histogram.has_key?(repo_id)
      # increment 
      occurance_histogram[repo_id] = occurance_histogram[repo_id] + 1
    end
  end
  # order by occurance decending
  nested = occurance_histogram.sort {|a,b| b[1]<=>a[1]}
  # covert to an array of repo ids
  ranked = []
  nested.each {|a| ranked << a[0]}  
  return nested
end

def apply_strategy(model) 
  # process all of the test users
  model.test_users.each do |user|
    # calculate user neighbours
    neighbours = calculate_neighbours(user)
    # rank repo's missing from user
    repos = rank_missing_repos(user, neighbours)
    # suggest top <=10 best whereever possible
    next if repos.nil? or repos.empty?
    repos.each_with_index do |r, i|
      break if i > MemDataModel.PREDICTION_MAX_REPOS
      user.add_prediction(r)
    end
  end
end


# load the model
model = MemDataModel.get_model
# apply strategy
puts "building prediction model using strategy: #{STRATEGY_NAME}..."
t = Utils.time {apply_strategy(model)}
puts "finished #{STRATEGY_NAME} prediction strategy in #{t} seconds"
# validate predicted model
t = Utils.time {model.validate_prediction_model}
puts "validated prediction result in #{t} seconds"
# output predicted model
t = Utils.time {model.output_prediction_model(STRATEGY_NAME)}
puts "output prediction result in #{t} seconds"

puts "finished"