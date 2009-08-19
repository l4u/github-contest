
# utilities 

module Utils 
  
  # block for measuring execution time, simply pass in work to execute
  # from: http://railsforum.com/viewtopic.php?id=23259
  def self.time
    start = Time.now
    yield
    Time.now - start
  end

  # FYI: http://www.techotopia.com/index.php/Working_with_Files_in_Ruby
  def self.fast_write_file(filename, data)
    File.open(filename, "w")  {|file| file.write(data) }
  end

  # returns an array of lines, closes the file automatically, no error handling
  # FYI: http://numericalruby.com/2007/06/22/reading-a-file-with-ruby/
  def self.fast_load_file(filename)    
    return File.open(filename, "r") { |file| file.readlines}
  end

  KILOBYTE = 1024
  MEGABYTE = 1024 * KILOBYTE

  #  looking for a speed increase
  # http://pleac.sourceforge.net/pleac_ruby/fileaccess.html
  def self.fast_load_file2(filename)
    # return nil on EOF
    data = ""
    t = time do 
      begin
         File.open filename, (File::RDONLY | File::NONBLOCK) do |io|
           tmp = nil
           until((tmp = io.read(MEGABYTE)).nil?)         
             data += tmp
           end
         end
      rescue Errno::ENOENT
         puts "no such file #{fname}"
      end
    end
    puts "loaded #{filename} in #{t} seconds"
    return data.split("\n")
  end
  
  def self.marshal_object(filename, object)
    t=Utils.time { File.open(filename, "w") { |f| Marshal.dump(object, f) } }
    
    # t = 0    
    # begin
    #   f = File.open(filename, "w")
    #   Marshal.dump(object, f) 
    #   f.close
    # rescue StandardError => myStandardError
    #   raise "problem: #{myStandardError}"
    # end
    
     puts "marshalled object to disk in #{t} seconds"
  end
  
  def self.unmarshal_object(filename)
    return nil if !File.exists?(filename)    
    object = nil
    t=Utils.time {object=File.open(filename, "r") { |f| Marshal.load(f) } }
    puts "unmarshalled object from disk in #{t} seconds"
    return object
  end
  
end

# testing
# lines = nil
# t = Utils.time {lines = Utils.fast_load_file2("../data/data.txt")}
# puts "loaded #{lines.size} lines in #{t} seconds"