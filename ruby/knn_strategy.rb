
# 
#  Name: k-nearest neighbour strategy
#  Description: calculate user neighbourhoods and suggest based on highest ranked missing repos
# 

require 'model'

def apply_strategy(model) 

end


STRATEGY_NAME = "kNN"

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