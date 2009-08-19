
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
  
  
  DATA_HOME = "../data"
  
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
  
  # static method 
  def self.get_model
    m = MemDataModel.new
    m.build
    return m
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
    puts "...loaded test #{@test_users.size} users #{DATA_TEST_USERS} in #{t.to_i} seconds"
  end
  
  def prep_second_order
    # repo parent hierarchies  
    t = time {attach_parent_repos}
    puts "...attached parent repositories in #{t.to_i} seconds"
    # repo owners
    
  end
  
  def attach_parent_repos
    attached = 0
    unattached = 0
    @repository_map.each do |id, repo|
      if(!repo.parent_id.nil?)
        if(!@repository_map[repo.parent_id].nil?)
          repo.parent_repo = @repository_map[repo.parent_id]
          attached = attached + 1
        else
          unattached = unattached + 1
        end
      end
    end
    puts "....#{(attached+unattached)} of #{@repository_map.size} repos have a parent (#{((attached+unattached)/@repository_map.size.to_f)*100}%), #{attached} of which were attached (#{(attached/(attached+unattached).to_f)*100}%)"
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
    puts "....loaded #{line_num} user-repository relationships"
  end
  
  def load_testusers
    unknown = 0
    line_num = 1
    fast_load_file("#{DATA_HOME}/#{DATA_TEST_USERS}").each do |line|
      begin
        line.strip!
        user_id = line
        # check for bad data
        if !@test_users[user_id].nil?
          puts ">duplicate test user id=#{user_id}, skipping"    
        else
          # ensure user is defined
          if @user_map[user_id].nil? 
            @user_map[user_id] = User.new(user_id)
            puts ">test user is not known, creating"
            unknown = unknown + 1
          end
          @user_map[user_id].test = true
          @test_users[user_id] = @user_map[user_id]
        end
      rescue StandardError => myStandardError
        raise "error on line #{line_num}: #{myStandardError}"
      end
      line_num = line_num + 1
    end
    puts "....defined #{@test_users.size} test users, #{unknown} of which are so-called new users"
  end
  
end



# testing
MemDataModel.get_model
