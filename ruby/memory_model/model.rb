
# 
#  In memory data model
#  Usage: m = Model.new.build

# TODO: save/load this thing from disk

require 'user'
require 'repository'
require 'utils'

class MemDataModel
  
  # id=>repository
  attr_accessor :repository_map
  # id=>user
  attr_accessor :user_map
  # id=>user
  attr_accessor :test_users
  
  
  DATA_HOME = "../../data"
  
  DATA_REPOS = "repos.txt"
  DATA_RELATIONSHIPS = "data.txt"
  DATA_REPO_LANGUAGES = "lang.txt"
  DATA_TEST_USERS = "test.txt"
  
  def initialize
    @repository_map = Hash.new
    @user_map = Hash.new
    @user_repository_map = Hash.new
    @test_users = Hash.new
  end
  
  def build
    t = time do
      puts "loading and preparing first order structures.."
      load_first_order
      puts "building second order structures..."
      prep_second_order
    end
    puts "memory model was built in #{t} seconds"
  end
  
  def load_first_order
    # repo
    t = time {load_repos}
    puts "...loaded #{@repository_map.size} repositories from #{DATA_REPOS} in #{t.to_i} seconds"
    # language data
    t = time {load_languages}
    puts "...loaded language data for repositories from #{DATA_REPO_LANGUAGES} in #{t.to_i} seconds"    
    # relationships
    t = time {load_relationships}
    puts "...loaded user-repository relationships from #{DATA_RELATIONSHIPS} in #{t.to_i} seconds"    
    # test users
    t = time {load_testusers}
    puts "...loaded test users #{DATA_TEST_USERS} in #{t.to_i} seconds"
  end
  
  def prep_second_order
    # repo parents
    
    # repo owners
    
  end
  
  def load_repos    
    line_num = 1
    fast_load_file("#{DATA_HOME}/#{DATA_REPOS}").each do |line|
      begin
        line.strip!
        repo = Repository.new(line)
        # check for bad data
        if !@repository_map[repo.id].nil?
          puts ">duplicate repository id=#{repo.id}, skipping" 
        else
          @repository_map[repo.id] = repo
        end
      rescue StandardError => myStandardError
        raise "error on line #{line_num}: #{myStandardError}"
      end
      line_num = line_num + 1
    end    
  end
  
  def load_languages
    line_num = 1
    num_skipped = 0
    fast_load_file("#{DATA_HOME}/#{DATA_REPO_LANGUAGES}").each do |line|
      begin
        line.strip!
        repo_id, blob = line.split(":")  
        # check for bad data
        if @repository_map[repo_id].nil?
          puts ">language definition for unknown repository id=#{repo_id}, skipping"
          num_skipped = num_skipped + 1
        else
          @repository_map[repo_id].parse_languages(line)
        end
      rescue StandardError => myStandardError
        raise "error on line #{line_num}: #{myStandardError}"
      end
      line_num = line_num + 1
    end
    puts "....loaded language data for #{line_num} repositories, #{num_skipped} of which were skipped"
  end
  
  def load_relationships
    line_num = 1
    fast_load_file("#{DATA_HOME}/#{DATA_RELATIONSHIPS}").each do |line|
      begin
        line.strip!
        user_id, repo_id = line.split(":")
        # check for bad data
        if @repository_map[repo_id].nil?
          puts ">relationship definition for unknown repository id=#{repo_id}, skipping" 
        else
          # ensure user is defined
          @user_map[user_id] = User.new(user_id) if @user_map[user_id].nil?
          # store relationship lots of ways
          @repository_map[repo_id].users[user_id] = @user_map[user_id]
          @user_map[user_id].repositories[repo_id] = @repository_map[repo_id]
        end
      rescue StandardError => myStandardError
        raise "error on line #{line_num}: #{myStandardError}"
      end
      line_num = line_num + 1
    end
  end
  
  def load_testusers
    line_num = 1
    fast_load_file("#{DATA_HOME}/#{DATA_TEST_USERS}").each do |line|
      begin
        line.strip!
        user_id = line
        # check for bad data
        if !@test_users[user_id].nil?
          puts ">duplicate users test user id=#{user_id}, skipping"          
        else
          # ensure user is defined
          @test_users[user_id] = User.new(user_id)
        end
        # check for test user is in training data
        if !@user_map[user_id].nil? 
          ">test user is in training data, id=#{user_id}"
        end
      rescue StandardError => myStandardError
        raise "error on line #{line_num}: #{myStandardError}"
      end
      line_num = line_num + 1
    end
  end
  
end


# testing
m = MemDataModel.new
m.build
