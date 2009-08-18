
class Repository 
  
  attr_accessor :id
  attr_accessor :fullname, :owner, :name
  attr_accessor :parent_id, :parent_repo
  attr_accessor :date
  attr_accessor :languages
  attr_accessor :users
  
  def initialize(line)
    parse_details(line)
    validate
    # prep structures
    @languages = Hash.new
    @users = Hash.new
  end
  
  # expect <id:owner/name,date,parent>
  # parent_id and owner are optional
  def parse_details(line)
    @id, blob = line.split(":")
    @fullname, @date, @parent_id = blob.split(",")
    @owner, @name = fullname.split("/")
  end
  
  # expect <name>;<lines>,<name>;<lines>,...
  def parse_languages(line)
    line.split(",").each do |pair| 
      lname, lines = pair.split(";")
      if lname.nil? or lname.empty? or lines.nil? or lines.empty? 
        raise "invalid language definition for repo #{@id}, data: #{pair}"
      else        
        @languages[lname] = lines
      end
    end
  end
  
  def validate
    raise "invalid id: #{@id}" if @id.empty? 
    raise "invalid fullname: #{@fullname}" if @fullname.nil? or @fullname.empty?
    raise "invalid name: #{@name}" if @name.nil? or @name.empty?
    raise "invalid date: #{@date}" if @date.nil? or @date.empty?  
  end
end