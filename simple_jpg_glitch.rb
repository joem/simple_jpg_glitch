require 'optparse'

usage_string = "Usage: #{File.basename($0)} [options] INPUTFILE"
@prng = Random.new

# Define the hash and set some sensible defaults
options = {
  number_of_iterations: 1,
  number_of_delete_lines: 1,
  number_of_delete_bytes: 1,
}
OptionParser.new do |parser|
  parser.banner = usage_string

  parser.on("-i", "--iteration [NUMBER]", Integer, "Number of output iterations to produce") do |num|
    options[:number_of_iterations] = num
  end

  parser.on("--delete-bytes [NUMBER]", Integer, "Number of times to delete random bytes") do |num|
    options[:number_of_delete_bytes] = num
  end

  parser.on("--delete-lines [NUMBER]", Integer, "Number of times to delete random line") do |num|
    options[:number_of_delete_lines] = num
  end

  parser.on("-r", "--random", "Do all glitches a random number of times", "(Note: This often results in an invalid jpg)") do |r|
    options[:random] = r
  end

  parser.on_tail("-h", "--help", "Show this message") do
    puts parser
    exit
  end
end.parse!
# after that, ARGV is an array of everything the user put for INPUTFILE

# If options[:random] is set, it's handled in the number of iterations loop so that each loop can get a different random amount.

# Make sure ARGV isn't empty
if ARGV.empty?
  $stderr.puts "Too few arguments."
  $stderr.puts usage_string
  exit 1
end

# Make sure ARGV only has one item
if ARGV.length != 1
  $stderr.puts "Too many arguments."
  $stderr.puts usage_string
  exit 1
end

options[:input_file] = ARGV[0]

# Make sure the item in ARGV is a file
if !File.file?(options[:input_file])
  $stderr.puts "File #{options[:input_file]} is not a real file."
  $stderr.puts usage_string
  exit 1
end


# Output the whole array as a file, without adding an extra linebreak at the end
def output_array(the_array, output_filename)
  File.open(output_filename, 'w+') do |f|
    the_array[0...-1].each do |element|
      f.puts element
    end
    f.print the_array.last
  end
end

# output_array(@lines, '1aa.jpg') #DEBUG


# Safely generate a new filename based on the provided name by suffixing a number.
# If the proposed file already exists, it increases the number and checks again.
# Continues until it finds a safe not-yet-existing filename and returns it.
def generate_name(original_name, startnum = 1)
  base = File.basename(original_name, File.extname(original_name))
  ext = File.extname(original_name)
  new_file = "#{base}-#{startnum}#{ext}"
  if File.file?(new_file)
    new_file = generate_name(original_name, startnum + 1)
  end
  return new_file
end

# p generate_name(options[:input_file]) #DEBUG


# Deletes a random element from the specified array.
# Note: Operates on the array itself, not a copy.
# `start_skip_lines` and `end_skip_lines` are just guesses at how to avoid the jpg header and footer.
# Returns the deleted line, in case you want to do something with it.
def glitch_delete_random_line!(the_array, start_skip_lines = 3, end_skip_lines = 2)
  line_to_skip = @prng.rand(start_skip_lines...(the_array.length - end_skip_lines))
  the_array.delete_at line_to_skip
end


# Deletes a random byte from a random element of the specified array.
# Note: Operates on the array itself, not a copy.
# `start_skip_lines` and `end_skip_lines` are just guesses at how to avoid the jpg header and footer.
# Returns the line after it was affected.
def glitch_delete_random_byte!(the_array, start_skip_lines = 3, end_skip_lines = 2)
  line_to_affect = @prng.rand(start_skip_lines...(the_array.length - end_skip_lines))
  byte_to_delete = @prng.rand(the_array[line_to_affect].bytesize)
  the_array[line_to_affect] = the_array[line_to_affect].byteslice(byte_to_delete)
end


# Do the actual operations!
options[:number_of_iterations].times do
  if options[:random]
    options[:number_of_delete_bytes] = 1 + @prng.rand(15)
    options[:number_of_delete_lines] = 1 + @prng.rand(15)
  end

  @lines = File.readlines(options[:input_file]) # Read file each time since the glitch is destructive
  options[:number_of_delete_lines].times do
    glitch_delete_random_line!(@lines)
  end
  options[:number_of_delete_bytes].times do
    glitch_delete_random_byte!(@lines)
  end
  new_file_name = generate_name(options[:input_file])
  puts "Outputting #{new_file_name}"
  output_array(@lines, new_file_name)
end

