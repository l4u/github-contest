
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
TESTING = false

def are_repos_related?(r1, r2)
  # same parent
  return true if (r1.parent_id == r2.parent_id)
  # is parent
  return true if (r1.id == r2.parent_id or r1.parent_id == r2.id)
  # TODO test second order relations
  return false
end

def do_repos_have_similar_composition?(r1, r2)
  # project language composition is >= 50%
  intersection = (r1.languages.keys & r2.languages.keys)
  return true if (intersection.size.to_f/r1.languages.size.to_f) >= 0.50
  return false
end

# arbitary scoring
def calculate_repo_similarity(user, repo_id, model)
  # test for hard match
  return 1.0 if user.has_repo?(repo_id)  
  repo = model.get_repo(repo_id)
  # test for related
  return 0.9 if user.repositories.any? {|r| are_repos_related?(model.get_repo(r), repo)}
  # test for composition similarities
  return 0.8 if user.repositories.any? {|r| do_repos_have_similar_composition?(model.get_repo(r), repo)}
  return 0.0
end

# larger == better
def calculate_user_scoring(user, other, model)
  # check for self
  return 0 if user.id.to_s == other.id.to_s
  # check for no repos
  return 0 if (user.repositories.empty? or other.repositories.empty?)
  # slow, but i'm exploring!
  score = 0.0  
  other.repositories.each do |r| 
    score = score + calculate_repo_similarity(user, r, model)
  end
  return score
end

# returns a set of K users in the users neighbourhood
def calculate_neighbours(user, all_users, model)
  # score all other users against user of interest
  all_neighbours = Hash.new
  all_users.each do |other| 
    score = calculate_user_scoring(user, other, model)
    next if score <= SCORE_CUT_OFF
    all_neighbours[other.id.to_s] = score
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

# returns a list of unique repo id ordered by neighbourhood occurance decending 
def rank_missing_repos(user, neighbours, model)
  return nil if neighbours.nil? or neighbours.empty?
  # build a histogram of repo occurance
  occurance_histogram = Hash.new
  neighbours.each do |neighbour_id|
    neighbour = model.get_user(neighbour_id)
    neighbour.repositories.each do |repo_id|
      # ensure user does not have it already
      next if user.has_repo?(repo_id)
      # create as needed
      occurance_histogram[repo_id.to_s] = 0 if !occurance_histogram.has_key?(repo_id.to_s)
      # increment 
      occurance_histogram[repo_id.to_s] = occurance_histogram[repo_id.to_s] + 1
    end
  end
  # order by occurance decending
  nested = occurance_histogram.sort {|a,b| b[1]<=>a[1]}
  # covert to an array of repo ids
  ranked = Array.new
  nested.each {|a| ranked << a[0]}    
  return ranked
end

def apply_strategy(model) 
  # process all of the test users
  model.all_test_users.each_with_index do |user_id, index|
    user = model.get_user(user_id)
    # user must have repos
    next if user.repositories.empty?
    # calculate user neighbours
    neighbours = calculate_neighbours(user, model.all_users, model)
    # rank repo's missing from user
    repos = rank_missing_repos(user, neighbours, model)
    # suggest top <=10 best wherever possible
    next if repos.nil? or repos.empty?
    repos.each_with_index do |repo_id, i|
      break if i >= PREDICTION_MAX_REPOS
      user.add_prediction(repo_id)
    end
    puts " > user (#{index + 1}/#{model.all_test_users.size}) id=#{user.id} with #{neighbours.size} neighbours was recommended #{user.predicted.size} repos" 
    break if (TESTING and index > 10)
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