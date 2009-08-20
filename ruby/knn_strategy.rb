
# 
#  Name: k-nearest neighbour strategy
#  Description: calculate user neighbourhoods and suggest based on highest ranked missing repos
# 
# it's all in the user distance baby!

# TODO marshal neighbourhood graph

require 'model'

PREDICTION_MAX_REPOS = 10
STRATEGY_NAME = "kNN"
K = 10
SCORE_CUT_OFF = 0

# larger == better
def calculate_user_scoring(user, other)
  return 0 if user.id == other.id
  dist = 0
  # hard match: repo intersection
  intersection = user.repositories & other.repositories
  dist = intersection.size
  
  return dist
end

# returns a set of K users in the users neighbourhood
def calculate_neighbours(user, all_users)
  # score all other users against user of interest
  all_neighbours = Hash.new
  all_users.values.each do |other| 
    next if other.id == user.id
    score = calculate_user_scoring(user, other)
    next if score <= SCORE_CUT_OFF
    all_neighbours[other.id] = score
  end
  # order by distance decending 
  nested = all_neighbours.sort {|a,b| b[1]<=>a[1]}
  # select the k best user id's
  neighbours = Array.new  
  nested.each_with_index do |a, i|
    break if i >= K
    neighbours << a[0]
  end
  # simple validation
  raise "too many neighbours #{neighbours.size}, expect #{K}" if neighbours.size > K
  return neighbours
end

# returns a list of unique repos ordered by neighbourhood occurance decending 
def rank_missing_repos(user, neighbours, model)
  return nil if neighbours.nil? or neighbours.empty?
  # build a histogram of repo occurance
  occurance_histogram = Hash.new
  neighbours.each do |neighbour_id|
    neighbour =  model.user_map[neighbour_id]
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
  ranked = Array.new
  nested.each {|a| ranked << a[0]}  
  return nested
end

def apply_strategy(model) 
  # process all of the test users
  model.test_users.each do |user_id|
    user =  model.user_map[user_id]
    # calculate user neighbours
    neighbours = calculate_neighbours(user, model.user_map)
    # rank repo's missing from user
    repos = rank_missing_repos(user, neighbours, model)
    # suggest top <=10 best whereever possible
    next if repos.nil? or repos.empty?
    repos.each_with_index do |r, i|
      break if i > PREDICTION_MAX_REPOS
      user.add_prediction(r)
    end
    puts " > user #{user.id} with #{neighbours.size} neighbours was recommended #{user.predicted} repos" 
  end
  puts "done."
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