#!/usr/bin/ruby
#
# Copyright:: Copyright 2012 Trimble Navigation Ltd.
# License:: Apache License, version 2.0
# Original Author:: Matt Lowrie 
# Author: Simone Nicolo 
#
# SketchUp plugin that tests the Ruby API.
#
# The TestUp utility provides a framework and GUI for running Ruby unit tests
# on the SketchUp Ruby API. The front-end is displayed in a SketchUp web dialog
# and tests are run in the standard Ruby unit test distribution.
#
#    ClassTestUp:   Provides the TestUp testing utility within SketchUp.
#

testup_path = File.expand_path(File.dirname(__FILE__))
ruby_packaged_path = File.join(testup_path, 'ruby')
ruby_testup_coverage_path = File.join(testup_path, 'coverage')

$LOAD_PATH << ruby_packaged_path
$LOAD_PATH << ruby_testup_coverage_path

require 'test/unit'
require 'test/unit/ui/console/testrunner'
require 'analyze_coverage'

# Factory class for instantiating the proper version of TestUp
#
class TestUp

  def self.new
    begin
      Sketchup
      # Check for the Sketchup module
      return TestUpSketchUp.new
    rescue NameError:
      nil  # Try the next one
    end

    begin
      # Check for the LayOut module
      LayOut
      return TestUpLayOut.new
    rescue NameError:
      nil
    end
  end
end


# This class provides the TestUp Ruby API testing utility within SketchUp.
#
#  The TestUp plugin begins by initializing with a web dialog showing the
#  testup.html page. When the page has finished loading, it sends a message
#  to the Ruby back-end to 'discover' all of the test case file located in the
#  /testup/tests directory. The Ruby back-end iterates each directory and ruby
#  file under this directory and sends the layout as a JSON string back to the
#  web front-end. The web front-end dynamically builds a GUI from the JSON
#  string. From the GUI users can select which tests to run, which gets sent
#  back to the Ruby back-end of a list of test cases to run in Ruby unit. The
#  Ruby unit results are then parsed and displayed in the web front-end.
#
# TODO(mlowrie): Inherit from TestUpBase
#
class TestUpSketchUp

  # Returns the expanded file path for a supplied file name that is next to
  # this script.
  #
  #
  # Returns:
  # - string: The expanded file path for the file name.
  def path_to_adjacent_file(file_name)
    return File.join(File.expand_path(File.dirname(__FILE__)), file_name)
  end

  # Shows the main GUI in a SketchUp web dialog and registers callbacks.
  #
  #
  def launch_gui()
    
    # Check if we're running on Mac so we can handle WebDialog differences.
    @is_mac = Object::RUBY_PLATFORM =~ /darwin/

    if @webdlg == nil
      # Shows a nicely sized WebDialog to display the plugin within.
      @webdlg = UI::WebDialog.new('TestUp', true,
                                  'TestUp', 800, 600, 100, 100, true)
      @webdlg.set_file path_to_adjacent_file('testup.html')
      # Add callbacks
      @webdlg.add_action_callback('gui_ready') do |dlg, param|
        gui_ready
      end
      @webdlg.add_action_callback('run') do |dlg, param|
        run_list = dlg.get_element_value('runList')
        run run_list
      end
    end

    # Show dialog "modally" if running on the mac, so that it doesn't
    # disappear behind SketchUp model windows.
    if @is_mac
      @webdlg.navigation_buttons_enabled = false
      @webdlg.show_modal
    else
      @webdlg.show
    end
  end

  # Performs steps to finish creating the GUI.
  #
  # This is a callback from the HTML page lets us know when the page is ready.
  # This function then performs the Ruby-side of setting up the plugin and
  # passing data to back to the HTML-side.
  #
  #
  # Args:
  # - dlg: The web dialog object displaying the HTML page.
  def gui_ready()
    path = path_to_adjacent_file 'tests'
    test_cases = read_test_dir path
    gui_json = test_cases.to_testup_json
    script = "createGui(#{gui_json});"
    @webdlg.execute_script script

    # This blurring forces an update so the mac displays TestUp
    # immediately after loading its content.
    if @is_mac
      @webdlg.execute_script('window.blur()')
    end
  end

  # Runs tests without the GUI.
  #
  #
  def auto_run()
    path = path_to_adjacent_file 'tests'
    test_cases = read_test_dir path
    test_list = ''
    test_cases.each_pair { |dir, data|
      # Define the test directories to run.
      # TODO(mlowrie): Maybe these should eventually be passed in. Hardcoding
      # for now.
      if /bugs_fixed/ =~ dir or /ruby_classes/ =~ dir
        UI.messagebox dir
        data['tests'].each { |filepath|
          test_list += filepath + ','
        }
      end
    }
    results_path = create_results_dir 'results'
    run_tests(test_list, results_path)
  end

  # Iterates the test directory, storing a list of .rb test files to run, along
  # with any HTML string that is found in a file called intro.html inside
  # each directory.
  #
  #
  # Args:
  # - path: Path to the directory to iterate.
  #
  # Returns:
  # - hash: A hash representing the test directory.
  #          {'dir1' => {'tests' => [f1, f2, ...], 'intro' => 'Intro HTML'},
  #          'dir2' => {'tests' => [f1, f2, ...], 'intro' => 'Intro HTML'}, ...}
  def read_test_dir(path)
    dir_hash = {}
    root_dir = Dir.new path
    root_dir.entries.each do |entry|
      cur_path = File.join(path, entry)
      # Check for directory names that do not begin with '.'
      if File.directory?(cur_path) && /^[^\.]/ =~ entry
        # Find all Ruby files in the current directory. These will be presented
        # as runnable tests.
        dir_hash[cur_path] = {}
        dir_hash[cur_path]['tests'] = Dir.glob("#{cur_path}/*.rb")

        # Attempt to read a file called "intro.html" inside our test directory.
        # If the file is found, pour its contents into our data structure
        # to be passed up to the UI. If not found, default to an empty string.
        begin
          intro_html = File::read(cur_path + '/intro.html')
          dir_hash[cur_path]['intro'] = intro_html
        rescue
          dir_hash[cur_path]['intro'] = ''
        end

      end
    end
    return dir_hash
  end

  # Runs the list of user-selected tests.
  #
  #
  # Args:
  # - test_list_str: A comma-separated string of file paths to the test cases
  #       the user has selected to run.
  def run(test_list_str)
    # analyze the paths to decide if you are in the ruby_classes tab
    # and therefore need coverage
    first_path = test_list_str.split(',').first
    coverage_required = first_path.include?("ruby_classes")

    results_path = create_results_dir 'results'
    result_files = run_tests(test_list_str, results_path)
    display_results(result_files, coverage_required)
  end

  # Creates the results directory in the same location as this script.
  #
  #
  # Returns:
  # - string: The result directory path.
  def create_results_dir(results_dir_name)
    # Create the results directory if it does not already exist
    results_dir_path = path_to_adjacent_file results_dir_name
    Dir.mkdir results_dir_path if not File.exists? results_dir_path

    # A time stamped directory to save the results of this test run
    ts = Time.now
    timestamp_dir_name = ts.strftime('%Y-%m-%d-%H-%M-%S-') + ts.usec.to_s
    results_path = File.join(results_dir_path, timestamp_dir_name)
    # Create the actual directory
    Dir.mkdir results_path
    return results_path
  end

  # Runs each test file in the test list in the unit test runner.
  #
  # TODO(mlowrie): This is dependant on the Ruby file name to be the same
  # as the Ruby test class name defined within it. The Ruby test classes
  # should be more discoverable.
  #
  #
  # Args:
  # - test_list_str: A comma-separated string of file paths to the test cases
  #       the user has selected to run.
  # - results_path: File path to the results directory of this test run.
  #
  # Returns:
  # - hash: Contains key, value pairs of file name => result file.
  def run_tests(test_list_str, results_path)
    # Load each test case file
    test_case_paths = test_list_str.split(',')
    test_case_paths.each { |path| load path.strip }

    result_files = {}

    # Go through each test case filename and run each test class
    test_case_paths.each do |path|
      # The is the id of the GUI element we want to set status on
      test_file = path.split('/').last
      # This is the Ruby class name we want to eval
      test_case = test_file.split('.').first
      results_file = File.join(results_path, test_case + '_results.txt')
      result_files[test_file] = results_file

      # Direct verbose test results to a file stream
      out_file = File.new(results_file, 'w')
      runner = Test::Unit::UI::Console::TestRunner.new(
          eval(test_case),
          Test::Unit::UI::VERBOSE,
          out_file)
      runner.start
      out_file.close
    end

    return result_files
  end

  # Parses the result files and sends data back to the GUI.
  #
  #
  # Args:
  # - result_files: A hash of test file name => result file pairs.
  # - coverage_required: A boolean value specifying if coverage is
  #   required.
  def display_results(result_files, coverage_required)
    total_pass = 0
    total_warn = 0
    total_fail = 0
    total_small = 0
    total_medium = 0
    total_large = 0

    result_files.each_pair do |test_file, results_file|
      # Now parse the results of this test run and update the GUI
      lines = File.readlines(results_file)
      test_case_stats = parse_results(lines)

      # For overall status, fail beats warn, which beats pass
      status = 'pass'
      status = 'warn' if test_case_stats[:warn] > 0
      status = 'fail' if test_case_stats[:fail] > 0

      # This sets the pass/fail/warn color of the GUI element
      set_gui_element_property(test_file, 'className', status)

      # This dumps the raw test case output into a toggable display element
      # First we need to escape double-quotes and remove new lines to avoid
      # javascript parsing errors
      raw_output = lines.join('<br/>').gsub(/"/, '\"').gsub(/\n/, '')

      # This color codes some of the output for easy scanning
      raw_output = raw_output.gsub(/\d+\) Error:/) { |m|
        "<span style=\\\"background-color: yellow\\\">#{m}</span>"
      }
      raw_output = raw_output.gsub(/\d+\) Failure:/) { |m|
        "<span style=\\\"background-color: red\\\">#{m}</span>"
      }

      set_gui_element_property(test_file + '_results', 'innerHTML', raw_output)

      total_pass += test_case_stats[:pass]
      total_warn += test_case_stats[:warn]
      total_fail += test_case_stats[:fail]
      total_small += test_case_stats[:small]
      total_medium += test_case_stats[:medium]
      total_large += test_case_stats[:large]
    end

    # Calculate the coverage data, only if in the ruby_classes tab
    if coverage_required
      ac = AnalyzeCoverage.new
      ac.run_coverage
      cov_html = File.join(ac.coverage_dir_path, 'testup_coverage.html')
    end

    # Calculate small, medium, large percentages.
    total = total_small + total_medium + total_large
    percent_small = (100.0 * (total_small.to_f / total.to_f)).to_i
    percent_medium = (100.0 * (total_medium.to_f / total.to_f)).ceil.to_i
    percent_large = 100 - percent_medium - percent_small

    # Set the heads-up display
    result_str = "<span class='fail'>#{total_fail}</span>" +
                 "<span class='warn'>#{total_warn}</span>" +
                 "<span class='pass'>#{total_pass}</span>" +
                 "<div id='percentages'>"

    # TODO(scottlininger): We probably don't need to calculate small/medium/
    #   large tests anymore. That was a Google thing. Hiding for now.
    # result_str += percent_small.to_s + "% small<br>" +
    #               percent_medium.to_s + "% medium<br>" +
    #               percent_large.to_s + "% large<br><br>"

    # display the coverage data if it is required
    if coverage_required
      result_str += "Unit Test Coverage: " + "%.2f" % ac.total_coverage +
                   "%<br>" + "<a href='#{cov_html}' target='_blank'>" +
                   "Coverage Details</a>"
    end
    result_str +="</div>"
    set_gui_element_property('headsUpDisplay', 'innerHTML', result_str)
  end

  # Grep the results to determine test status
  #
  #
  # Args:
  # - results_lines: The array of lines from the test output file.
  #
  # Returns:
  # - hash: Count of each test case status,
  #         {pass => count, warn => count, fail=> count}.
  def parse_results(results_lines)
    stats = {:pass => 0, :warn => 0, :fail =>0,
             :small =>0, :medium =>0, :large =>0}
    results_lines.each do |line|
      if /^test_/ =~ line
        stats[:pass] += 1 if /\.$/ =~ line
        stats[:warn] += 1 if /E$/ =~ line
        stats[:fail] += 1 if /F$/ =~ line

        # If the method does not end in '_medium' or '_large' then assume it
        # is a small test.
        method_name = line[0..(line.index('(')-1)]
        if /_large$/ =~ method_name
          stats[:large] += 1
        elsif /_medium$/ =~ method_name
          stats[:medium] += 1
        else
          stats[:small] += 1
        end
      end
    end
    return stats
  end

  # Executes a function on the HTML-side so change an element property.
  #
  #
  # Args:
  # - element_name: The HTML element id.
  # - property_name: The element property to change the value of.
  # - value: The new value of the element property.
  def set_gui_element_property(element_id, property_name, value)
    script = "setGuiElementProperty(\"#{element_id}\", \"#{property_name}\", " +
             "\"#{value}\");"
    @webdlg.execute_script script
  end
end


# Base class for functionality common to TestUp for SketchUp and LayOut
#
class TestUpBase

  # Class initializer
  #
  # We keep all test classes in an instance variable, since they can only be
  # loaded into scope once. Once loaded we need to hang on to it symbol in the
  # current scope so that it can be re-run if requested by the user.
  #
  # The structure of the test storage is:
  # @test_categories[<category name>]['files'][<list of file paths>]
  #                                  ['intro']'<intro html>'
  #
  def initialize(test_directory=nil)
    @test_categories = {}
  end

  # Returns the expanded file path for a supplied file name that is next to
  # this script.
  #
  # Returns:
  # - string: The expanded file path for the file name.
  def path_to_adjacent_file(file_name)
    return File.join(File.expand_path(File.dirname(__FILE__)), file_name)
  end

  # Loads the script and gets the new classes inserted into the current scope
  #
  # Relies on custom methods added to the Test::Unit::TestCase class
  #
  # Args:
  # - file_path: A string of the file path to the ruby script to load.
  #
  # Returns:
  # - array: A list of classes loaded by the ruby script.
  #
  def get_test_cases_from_file(file_path)
    # Loading the ruby script create the test class objects, which in turn will
    # trigger the inherited() callback we defined on TestCase class
    load file_path
    test_cases = Test::Unit::TestCase.get_and_reset_inherited_classes
    return test_cases
  end

  # Creates the results directory in the same location as this script.
  #
  # Args:
  # - results_dir_name: A string to use for the name of the results directory.
  #
  # Returns:
  # - string: A string of the file path to the results directory.
  def create_results_dir(results_dir_name)
    # Create the results directory if it does not already exist
    results_dir_path = path_to_adjacent_file(results_dir_name)
    Dir.mkdir(results_dir_path) if not File.exists?(results_dir_path)

    # A time stamped directory to save the results of this test run
    ts = Time.now
    timestamp_dir_name = ts.strftime('%Y-%m-%d-%H-%M-%S-') + ts.usec.to_s
    results_path = File.join(results_dir_path, timestamp_dir_name)
    # Create the actual directory
    Dir.mkdir(results_path)
    return results_path
  end

  # Iterates the test directory, finding all test files
  #
  # Collects all file paths and test classes, and stores them in the instance
  # variable @test_categories. The top-level test directory holds subdirectories
  # which act as test categories. Each subdirectory holds a list of test files
  # for that category, i.e.:
  # root_test_dir
  #  |_ category1
  #  |___ test1.rb
  #  |___ test2.rb
  #  |___ test_foo.rb
  #  |_ category2
  #  |___ test1.rb
  #  |___ test2.rb
  #  |___ test3.rb
  #  |___ test_bar.rb
  #  |___ etc...
  #
  # Args:
  # - path: A string of the file path to the directory that holds all tests
  #
  def find_all_tests(path)
    root_dir = Dir.new(path)
    root_dir.entries.each do |entry|
      entry_path = File.join(path, entry)
      # We only look for sub directories in the root directory, whose names do
      # not begin with '.'. Each directory name defines a test category
      if File.directory?(entry_path) && /^[^\.]/ =~ entry
        # Create a lookup table for this test category if one does not exist
        if not @test_categories.has_key?(entry)
          @test_categories[entry] = {}
          @test_categories[entry]['tests'] = {}
        end
        # Find all Ruby files in the current directory. These will be presented
        # as runnable tests.
        ruby_files = Dir.glob("#{entry_path}/*.rb")
        # While here, might as well load the initial set of test cases
        ruby_files.each do |ruby_file|
          test_cases = get_test_cases_from_file(ruby_file)
          if not @test_categories[entry]['tests'].has_key?(ruby_file)
            @test_categories[entry]['tests'][ruby_file] = []
          end
          @test_categories[entry]['tests'][ruby_file] += test_cases
        end

        # Attempt to read a file called "intro.html" inside our test directory.
        # If the file is found, pour its contents into our data structure
        # to be passed up to the UI. If not found, default to an empty string.
        intro_file = File.join(entry_path, 'intro.html')
        if File.exists?(intro_file)
          intro_html = File::read(intro_file)
          @test_categories[entry]['intro'] = intro_html
        else
          @test_categories[entry]['intro'] = nil
        end
      end
    end
  end

  # Runs the collection of test classes
  #
  # Iterates through the @test_category list and runs each test class in a
  # Ruby unit TestRunner. Results are saved out to disc after each test to
  # keep a log in case the application crashes during a test run.
  #
  # Args:
  # - test_dir: A string of the file path to the test directory.
  # - results_dir: A string of the file path to the results directory.
  # - categories_to_run: An array of test category names as strings to run. The
  #                      default is an empty array, which means run all tests.
  #
  # Returns:
  # - hash: Keys: Each test file path. Values: An array of test result output
  #         for that test file.
  #
  def run_tests(test_dir, results_dir, categories_to_run=[])
    results = {}

    @test_categories.each do |category, data|
      # Check if we were asked to run tests in this category
      if categories_to_run.empty? or categories_to_run.include?(category)

        data['tests'].each do |path, test_classes|
          # Collect the results for tests in this file
          results[path] = []

          # Run each test
          test_classes.each do |test|
            results_collector = ResultsCollector.new
            runner = Test::Unit::UI::Console::TestRunner.new(
              test, Test::Unit::UI::VERBOSE, results_collector
            )
            runner.start
            results[path] << results_collector.to_s
          end

          # We need to write out all the results once we have them in case the
          # application crashes during the test run.
          results_file_name = File.basename(path, File.extname(path)) + '.txt'
          results_file_path = File.join(results_dir, results_file_name)
          output_file = File.open(results_file_path, 'w')
          output_file.write(results[path].join("\n\n"))
          output_file.close
        end
      end
    end
    return results
  end

  # Presents the results to the user
  #
  # Launches a dump of the results in a web browser.
  #
  # Args:
  # - results: A hash of test results for each test file.
  # - results_dir: A string of the file path to the results directory.
  #
  def show_results(results, results_dir)
    html = []
    results.each do |path, output|
      html << path + "\n"
      html += output
    end
    results_html_file = File.join(results_dir, 'results.html')
    open_file = File.open(results_html_file, 'w')
    open_file.write('<pre>')
    open_file.write(html.join('<br/>'))
    open_file.write('</pre>')
    open_file.close
    if /mswin/ =~ RUBY_PLATFORM
      system("start #{results_html_file}")
    end
  end
end


# TestUp class for running in LayOut.
#
class TestUpLayOut < TestUpBase

  # Class initializer
  #
  # Args:
  # - test_directory: A string of a file path to a directory containing LayOut
  #                   TestUp tests.
  #
  def initialize(test_directory=nil)
    super
    # Use a default test directory if none supplied
    @test_directory = test_directory.nil? ? 'tests_layout' : test_directory
  end

  # Performs a test run of TestUp
  #
  def run
    test_dir_path = path_to_adjacent_file(@test_directory)
    results_dir_path = create_results_dir('results')
    # We need to run this each time in case test case files have changed or new
    # tests have been added
    find_all_tests(test_dir_path)
    results = run_tests(test_dir_path, results_dir_path)
    show_results(results, results_dir_path)
  end
end


# Mimics an IO class to collect results in memory from the TestRunner.
#
class ResultsCollector

  # Allow read access to the @output instance varialble
  attr_reader :output

  # Class initializer
  #
  def initialize
    @output = []
  end

  # Stub for puts method
  #
  def puts msg
    @output << msg
  end

  # Stub for write method
  #
  def write msg
    @output << msg
  end

  # Stub for flush method
  #
  # Does nothing since all data is in memory
  #
  def flush
    nil
  end

  # Overrides to_s to return the results as a string
  #
  # Returns:
  # - string: The collected result output as a single string
  #
  def to_s
    return @output.join("\n")
  end
end


# Open up the TestCase class to add methods for detecting inheritance
#
# As each TestUp test case is loaded into scope, the inherited() callback will
# be triggered so we can keep a collection of each test case class.
#
class Test::Unit::TestCase

  # Keeps track of newly loaded test classes
  @@inherited_list = []

  # Alias inherited() in case it is already defined
  #
  class << self
    alias_method :old_inherited, :inherited
  end

  # Adds a newly inherited class to the list
  #
  def self.record_inherited_cls cls
    @@inherited_list << cls
  end

  # Inherited callback
  #
  # Creates an inherited callback which gets called when each test case is
  # loaded into scope.
  #
  # Args:
  # - descendant: The class which inherited from TestCase
  #
  def self.inherited decendant
    self.record_inherited_cls decendant
    # Call the original inherited method
    old_inherited(decendant)
  end

  # Gets the list of classes and resets the list
  #
  # Reads the collected classes and resets the instance variable for the next
  # callback session.
  #
  # Returns:
  # - array: A list of test class objects
  #
  def self.get_and_reset_inherited_classes
    return_list = @@inherited_list
    @@inherited_list = []
    return return_list
  end
end


################################################################################
# Personalized JSON section

# Opens up the String class to add a method for converting to simple JSON
#
class String

  # Personalized method to give us JSON from a String.
  #
  alias_method :to_testup_json, :inspect
end


# Opens up the Numeric class to add a method for converting to simple JSON
#
class Numeric

  # Personalized method to give us JSON from a Numeric.
  #
  alias_method :to_testup_json, :inspect
end


# Opens up the Array class to add a method for converting to simple JSON
#
class Array

  # Custom method giving JSON from an Array containing Strings and Numerics.
  #
  # Returns:
  # - string: A JSON string of the Array.
  def to_testup_json
    inside = map { |elem| elem.to_testup_json }.join(',')
    return "[#{inside}]"
  end
end


# Opens up the Hash class to add a method for converting to simple JSON
#
class Hash

  # Adds a personalized method to the Hash class for this script.
  #
  # This method is specialized to convert our data stored in a Hash to a JSON
  # string that we can send to the web front-end. It is by no means a
  # comprehensive translation to the JSON spec.
  #
  # Returns:
  # - string: A JSON string representation of a Hash.
  #
  def to_testup_json
    inside = map { |k, v| "#{k.to_testup_json}:#{v.to_testup_json}" }.join(',')
    return "{#{inside}}"
  end
end
