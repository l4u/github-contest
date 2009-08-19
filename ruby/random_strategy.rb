
# 
#  Name: random strategy
#  Description: generate a random valid set of repositories for each test user and store as ../results.txt
# 

require 'model'


def random_repo(all_repos)
  return all_repos[Kernel.rand(all_repos.size)]
end

def apply_strategy(model)
  # list of all repos
  all_repos = model.repository_map.values
  # process all of the test users
  model.test_users.each do |user| 
    # may have 0..10 predicted repos
    num_repos = Kernel.rand(10 + 1)
    num_repos.times do
      # generate & test
      done = false
      until(done)
        repo = random_repo(all_repos)
        done = true if !user.has_or_predicted_repo?(repo)
      end
      # add
      user.add_prediction(repo)
    end  
  end
end

STRATEGY_NAME = "Random"

# load the model
model = MemDataModel.get_model
# apply strategy
puts "building prediction model using strategy: #{STRATEGY_NAME}..."
t = time {apply_strategy(model)}
puts "finished #{STRATEGY_NAME} prediction strategy in #{t} seconds"
# validate predicted model
t = time {model.validate_prediction_model}
puts "validated prediction result in #{t} seconds"
# output predicted model
t = time {model.output_prediction_model(STRATEGY_NAME)}
puts "output prediction result in #{t} seconds"

puts "finished"