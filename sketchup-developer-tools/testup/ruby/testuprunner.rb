require 'test/unit'
require 'test/unit/ui/console/testrunner'

# Create the results directory if it does not already exist
results_dir_name = "results"
begin
  Dir.mkdir(results_dir_name)
rescue
  # Results directory already exists
end

# This should be a probablistically unique name and not already exist
ts = Time.now
timestamp_dir_name = ts.strftime("%y.%m.%d.%H.%M.%S") + '-' + ts.to_i.to_s
Dir.mkdir("%s/%s" % [results_dir_name, timestamp_dir_name])

# Read the manifest file and load each test ruby script
test_case_paths = IO.readlines('test_cases.man')
test_case_paths.each { |path| load path.strip }
test_case_files = test_case_paths.map { |path| path.split('\\').last }

# Go through each test case filename and run each test class
test_case_files.each { |test_case|
  # Remove the .rb extension
  test_case = test_case.split('.').first
  
  results_file = "%s/%s/%s" % [
      results_dir_name,
      timestamp_dir_name,
      test_case + '_results.txt']

  # Direct verbose test results to a file stream
  out_file = File.new(results_file, 'w')
  runner = Test::Unit::UI::Console::TestRunner.new(
      eval(test_case),
      Test::Unit::UI::VERBOSE,
      out_file)
  runner.start()
  out_file.close()
}

# Notify the calling process that we are done
File.new('DONE', 'w').close()
