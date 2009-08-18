
# utilities 

# block for measuring execution time, simply pass in work to execute
# from: http://railsforum.com/viewtopic.php?id=23259
def time
  start = Time.now
  yield
  Time.now - start
end

# returns an array of lines, closes the file automatically, no error handling
# FYI: http://numericalruby.com/2007/06/22/reading-a-file-with-ruby/
def fast_load_file(filename)    
  return File.open(filename, "r") { |file| file.readlines}
end

KILOBYTE = 1024
MEGABYTE = 1024 * KILOBYTE

#  looking for a speed increase
# http://pleac.sourceforge.net/pleac_ruby/fileaccess.html
def fast_load_file2(filename)
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

# testing
# start = Time.now
# lines = fast_load_file2("../../data/data.txt")
# t = Time.now - start
# puts "loaded #{lines.size} lines in #{t} seconds"