
# 
#  In memory data model
#  Usage: m = MemDataModel.get_model
# 
# It will attempt to load the model from disk otherwise create and marshal it for next time 
# loads factor of 3+ times faster from mashaled version than building it again

require 'user'
require 'repository'
require 'utils'

class MemDataModel
  
  # # id=>repository
  # attr_accessor :repository_map
  # # id=>user
  # attr_accessor :user_map
  # # user
  # attr_accessor :test_users
  
  
  DATA_HOME = "../data"
  BACKUP_HOME = "../backup"
  RESULTS_HOME = "../"
  
  MODEL_MARSHAL = "marshaled_mode.bin"   
  
  DATA_REPOS = "repos.txt"
  DATA_RELATIONSHIPS = "data.txt"
  DATA_REPO_LANGUAGES = "lang.txt"
  DATA_TEST_USERS = "test.txt"
  DATA_RESULTS = "results.txt"
  
  PREDICTION_MAX_REPOS = 10
  

  def initialize
    @repository_map = Hash.new
    @user_map = Hash.new
    @test_users = Array.new
  end
  
  # 
  # note: these are all-decouled (mediated methods)
  # so we can change the underlying model without messing it all up
  # 
  
  def get_repo(repo_id)
    return @repository_map[repo_id.to_s]
  end
  
  def repo_exists?(repo_id)
    return @repository_map.has_key?(repo_id.to_s)
  end
  
  def get_user(user_id)
    return @user_map[user_id.to_s]
  end
  
  def user_exists?(user_id)
   return @user_map.has_key?(user_id.to_s)
  end
  
  def all_repos
    return @repository_map.values
  end
  
  def all_users
    return @user_map.values
  end
  
  def all_test_users
    return @test_users
  end
  
  
  def print_model_stats
    puts "model stats:"
    puts "repositories:.....#{@repository_map.size}"
    puts "users:............#{@user_map.size}"
    puts "test users:.......#{@test_users.size}"
    puts "non-test users:...#{@user_map.size - @test_users.size}"
  end
  
  # static method 
  def self.get_model
    # try and load     
    model = Utils.unmarshal_object(MODEL_MARSHAL)
    if model.nil?
      # build
      model = MemDataModel.new
      model.build
      Utils.marshal_object(MODEL_MARSHAL, model)
    end
    return model
  end
  
  def validate_prediction_model
    @test_users.each do |user_id|
      user = get_user(user_id)
      # check size
      if user.predicted.size > PREDICTION_MAX_REPOS
        raise "user has an invalid number of predicted repositories: #{user.predicted.size}"
      end
      # validate predicted repos
      user.predicted.each do |repo_id|
        # must be a valid repo
        if !repo_exists?(repo_id)
          raise "user #{user.id} predicted repo id #{repo_id} that is not a known repo"
        end
        # must not already be in use
        if user.has_repo?(repo_id)
          raise "user predicted repository [#{repo_id}] that they already use"
        end
      end      
    end
  end
  
  # does the results.txt have to be in the same order as the test.txt? (yes now now...)
  # does the order of the predictions have an effect?
  def output_prediction_model(strategy)
    data = ""
    all_test_users.each do |user_id|
      user = get_user(user_id)
      data << "#{user.get_prediction_string}\n"
    end
    # output a backup
    Utils.fast_write_file("#{BACKUP_HOME}/#{strategy}-#{Time.now.to_i}-#{DATA_RESULTS}", data)    
    # output in default location
    Utils.fast_write_file("#{RESULTS_HOME}/#{DATA_RESULTS}", data)
  end
  
  def build
    t = Utils.time do
      puts "loading and preparing first order structures.."
      load_first_order
      puts "building second order structures..."
      prep_second_order
    end
    puts "memory model was built in #{t} seconds"
  end
  
  def load_first_order
    # repo
    t = Utils.time {load_repos}
    puts "...loaded #{@repository_map.size} repositories from #{DATA_REPOS} in #{t.to_i} seconds"
    # language data
    t = Utils.time {load_languages}
    puts "...loaded language data for repositories from #{DATA_REPO_LANGUAGES} in #{t.to_i} seconds"    
    # # relationships
    t = Utils.time {load_relationships}
    puts "...loaded user-repository relationships from #{DATA_RELATIONSHIPS} in #{t.to_i} seconds"    
    # # test users
    t = Utils.time {load_testusers}
    puts "...loaded test #{@test_users.size} users #{DATA_TEST_USERS} in #{t.to_i} seconds"
  end
  
  def prep_second_order

  end
  
  
  def load_repos    
    line_num = 1
    Utils.fast_load_file("#{DATA_HOME}/#{DATA_REPOS}").each do |line|
      begin
        line.strip!
        repo = Repository.new(line)
        # check for bad data
        if repo_exists?(repo.id)
          puts ">duplicate repository id=#{repo.id}, skipping" 
        else
          @repository_map[repo.id.to_s] = repo
        end
      rescue StandardError => myStandardError
        raise "error on line #{line_num}: line=#{line}, error=#{myStandardError}"
      end
      line_num = line_num + 1
    end    
  end
  
  def load_languages
    line_num = 1
    num_skipped = 0
    Utils.fast_load_file("#{DATA_HOME}/#{DATA_REPO_LANGUAGES}").each do |line|
      begin
        line.strip!
        repo_id, blob = line.split(":")  
        # check for bad data
        if !repo_exists?(repo_id)
          puts ">language definition for unknown repository id=#{repo_id}, skipping"
          num_skipped = num_skipped + 1
        else
          get_repo(repo_id).parse_languages(line)
        end
      rescue StandardError => myStandardError
        raise "error on line #{line_num}: line=#{line}, error=#{myStandardError}"
      end
      line_num = line_num + 1
    end
    puts "....loaded language data for #{line_num} repositories, #{num_skipped} of which were skipped"
  end
  
  def load_relationships
    line_num = 1
    Utils.fast_load_file("#{DATA_HOME}/#{DATA_RELATIONSHIPS}").each do |line|
      begin
        line.strip!
        user_id, repo_id = line.split(":")
        # check for bad data
        if !repo_exists?(repo_id)
          puts ">relationship definition for unknown repository id=#{repo_id}, skipping" 
        else
          # ensure user is defined
          @user_map[user_id.to_s] = User.new(user_id) if !user_exists?(user_id)
          # store relationship lots of ways
          get_repo(repo_id).add_user(user_id)
          get_user(user_id).add_repo(repo_id)
        end
      rescue StandardError => myStandardError
        raise "error on line #{line_num}: line=#{line}, error=#{myStandardError}"
      end
      line_num = line_num + 1
    end
    puts "....loaded #{line_num} user-repository relationships"
  end
  
  def load_testusers
    unknown = 0
    line_num = 1
    Utils.fast_load_file("#{DATA_HOME}/#{DATA_TEST_USERS}").each do |line|
      begin
        line.strip!
        user_id = line
        # ensure user is defined
        if !user_exists?(user_id)
          @user_map[user_id.to_s] = User.new(user_id)
          puts ">test user is not known, creating"
          unknown = unknown + 1
        end          
        if(get_user(user_id).test) 
          puts ">user already marked as a test user, duplicate in file: #{user_id}"
        else
          get_user(user_id).test = true
          @test_users << user_id.to_s
        end
      rescue StandardError => myStandardError
        raise "error on line #{line_num}: line=#{line}, error=#{myStandardError}"
      end
      line_num = line_num + 1
    end
    puts "....defined #{@test_users.size} test users, #{unknown} of which are so-called new users"
  end
  
end


# testing
# m = MemDataModel.get_model
# m.print_model_stats
