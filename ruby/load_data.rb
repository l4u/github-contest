# 
# Load the provided data into a mysql database
# (only run once)
# 

require 'rubygems'
require 'activerecord'

require 'user'
require 'repository'
require 'user_repository'
require 'repository_language'

#  cfg
db_name = "github_contest"
data_dir = "../data"
loadtest = false
loadtest_max = 10000

# 
# connect, presume DB is already created
#  => create database github_contest;
# 

puts "connecting to database: #{db_name}"
ActiveRecord::Base.establish_connection(
  :adapter  => "mysql",
  :host     => "localhost",
  :username => "root",
  :password => "",
  :database => db_name
)

# 
# define tables
# 
puts "creating tables"
ActiveRecord::Schema.define :version => 0 do
  # drop all
  drop_table :users
  drop_table :repositories
  drop_table :user_repositories
  drop_table :repository_languages
  
  # user
  create_table :users, :force => true do |t|
    t.integer   :user_id
    t.integer   :test, :default=>0
  end
  # repo
  create_table :repositories, :force => true do |t|    
    t.integer   :repository_id
    t.string    :fullname, :null => true  
    t.string    :username, :null => true  
    t.string    :name, :null => true 
    t.date      :date, :null => true
    t.integer   :parent_id, :null => true      
  end
  # user-repo
  create_table :user_repositories, :force => true do |t|    
    t.integer    :user_id
    t.integer    :repository_id
  end
  # language
  create_table :repository_languages, :force => true do |t|          
    t.integer     :repository_id
    t.string      :name
    t.integer     :lines
  end
end

# 
# process repos.txt
# 
counter = 1
begin
  file = File.new("#{data_dir}/repos.txt", "r")
  while (line = file.gets)
    # chop it up
    repo_id, blob = line.split(":")    
    repo_fullname, repo_date, repo_parent = blob.split(",")
    repo_name, repo_username = repo_fullname.split("/")
    # repo
    repo = Repository.find_by_repository_id(repo_id)
    if !repo.nil?
      puts "=> Repository[#{repo_id}] already exists, bad data!"      
    else
      repo = Repository.new
      repo.repository_id = repo_id
      repo.fullname = repo_fullname
      repo.date = repo_date
      repo.name = repo_name
      repo.username = repo_username
      repo.parent_id = repo_parent
      repo.save!
    end 
    # count
    counter = counter + 1
    # testing...
    break if loadtest and counter > loadtest_max    
  end
  file.close
rescue => err
  puts "Exception: #{err}"
  err
end
puts "repos.txt, processed #{counter} lines"

# 
# process data.text
# 
counter = 1
begin
  file = File.new("#{data_dir}/data.txt", "r")
  while (line = file.gets)
    user_id, repo_id = line.split(":")    
    # user
    user = User.find_by_user_id(user_id)
    if user.nil?
      user = User.new
      user.user_id = user_id
      user.save!
    end
    # repo
    repo=Repository.find_by_repository_id(repo_id)
    if repo.nil?
      repo = Repository.new
      repo.repository_id = repo_id
      repo.save!
    end
    # user repo
    if !UserRepository.find_by_user_id_and_repository_id(user_id, repo_id).nil?
      puts "=> User[#{user_id}] Repository[#{repo_id}] relationship already defined, bad data!"
    else
      userrepo = UserRepository.new
      userrepo.user_id = user.id
      userrepo.repository_id = repo.id
      userrepo.save!
    end
    # count
    counter = counter + 1
    # testing...
    break if loadtest and counter > loadtest_max    
  end
  file.close
rescue => err
  puts "Exception: #{err}"
  err
end
puts "data.txt, processed #{counter} lines"


# 
# process lang.txt
# 
counter = 1
begin
  file = File.new("#{data_dir}/lang.txt", "r")
  while (line = file.gets)
    # chop it up
    repo_id, blob = line.split(":")        
    # repo
    repo = Repository.find_by_repository_id(repo_id)
    if repo.nil?
      puts "=> Repository[#{repo_id}] does not exist, bad data!"
    else
      # process langs
      blob.split(",").each do |language| 
        name, lines = language.split(";")
        lang = RepositoryLanguage.new
        lang.repository_id = repo.id
        lang.name = name;
        lang.lines = lines
        lang.save!
      end
    end        
    # count
    counter = counter + 1
    # testing...
    break if loadtest and counter > loadtest_max      
  end
  file.close
rescue => err
  puts "Exception: #{err}"
  err
end
puts "lang.txt, processed #{counter} lines"

# 
# process test.txt
# 
counter = 1
begin
  file = File.new("#{data_dir}/test.txt", "r")
  while (line = file.gets)
    user_id, repo_id = line.split(":")    
    # user
    user = User.find_by_user_id(user_id)
    if user.nil?
      user = User.new
      user.user_id = user_id
      user.test = 1
    else
      user.test = 1
    end
    # save
    user.save!    
    # count
    counter = counter + 1
    # testing...
    break if loadtest and counter > loadtest_max    
  end
  file.close
rescue => err
  puts "Exception: #{err}"
  err
end
puts "test.txt, processed #{counter} lines"

# 
# stats
# 
puts "STATS"
puts "Users:...............#{User.count}"
puts "Repositories:........#{Repository.count}"
puts "UserRepositories:....#{UserRepository.count}"
puts "RepositoryLanguages:.#{RepositoryLanguage.count}"
