
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