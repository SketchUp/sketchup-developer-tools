#!/usr/bin/ruby -w
#
# Copyright:: Copyright 2012 Trimble Navigation Inc.
# License:: Apache License, version 2.0
# Original Author:: Simone Nicolo
#
# This class has functionality to analyze Ruby Functions coverage
# From Within TestUp. It is called only when we are running the
# ruby functions unit tests.
#
# The overall workflow is as follows, we create a master list of all
# the Ruby function in the API (@full_functions_list) from a golden list in
# Google_SketchUp_Ruby_Methods.csv, created using ourdoc_coverage.rb.
# Then we create an array of functions (@functions_to_match) that have
# passed their tests by analyzing the results logs.
#
# Then we compare the two list and compute gobal coverage and per class
# coverage.
#
# Finally we create an HTML page with the detailed coverage results
# breakdown.
#
#    ClassAnalyzeCoverage:   Provides the code coverage functionality
#                            within TestUp.
#
class AnalyzeCoverage

  # Provide read access to the class variables needed by
  # TestUp to display coverage data in its webdialog.
  attr_reader :total_coverage, :coverage_dir_path

  # This function initialize several class variables, including the various
  # directory paths needed to compute coverage.
  #
  # Args:
  #   - None
  #
  # Returns:
  #   - None
  def initialize
    @functions_to_match = []
    @full_functions_list = {}
    @per_class_coverage = {}
    @total_coverage = 0

    script_file_path = File.expand_path(File.dirname(__FILE__))
    Dir.chdir(script_file_path)
    Dir.chdir("..")
    testup_root = Dir.pwd
    @results_dir_path = File.join(testup_root, 'results', '*')
    @coverage_dir_path = File.join(testup_root, 'coverage')
    dirs = Dir.glob(@results_dir_path)
    last_run_results = dirs.last
    path = File.join(last_run_results,'*.txt')
    @txts = Dir.glob(path)

  end

  # This function is the main driving function to collect code coverage.
  #
  # Args:
  #   - None
  #
  # Returns:
  #   - None
  def run_coverage
    # This function creates the master list of all the Ruby functions
    # and stores it in the hash @full_functions_list.
    create_cov_lists

    # @txts holds all the results files we need to analyze to compute coverage.
    @txts.each do |file|
      f = File.open(file, 'r')
      lines = f.readlines()
      # get the class name
      class_name = file.split('_')[1]

      lines.each do |line|
        parts = line.split(':')

        if ( parts[0].include?('test_') and
            not (parts[0].include?('[')) and
            not (parts[1].nil?) )

          function = parts[0].to_s
          result = parts[1].rstrip!.to_s

          # if the test passed
          if result.include?('.')
            # add the function and class name to the list to be compared
            # to the full functions list.
            name_to_match = class_name + '.' + function_name(function)
            @functions_to_match << name_to_match
          end
        end
      end
    end

    # Compare the full functions list with the list of functions that
    # had a test that passed.
    @full_functions_list.each_pair do |k,v|
      # match on key, which has the classname.functionname format.
      @functions_to_match.each do |test|
        class_name_from_test = test.split('.')[0]
        class_name_from_list = @full_functions_list[k][:class]
        # if it contains the pattern
        if class_name_from_test.eql?(class_name_from_list) and test.downcase.include?(k.downcase)
        # mark it as covered
          @full_functions_list[k][:covered] = true
          @full_functions_list[k][:tests] += 1
        end
      end
    end

    # This function will compute per class coverage and total coverage from
    # the @full_function_list hash.
    compute_coverage

  end

  # This function computes total coverage and per class coverage
  # (stored in the hash @per_class_coverage), and generates an
  # html page that contains detailed per class coverage information.
  #
  # Args:
  #   - None
  #
  # Returns:
  #   - None
  def compute_coverage
    covered_functions = 0
    all_functions = 0

    @full_functions_list.each_pair do |k,v|
      current_class = v[:class]
      current_function = v[:function]

      if v[:covered]
        @per_class_coverage[current_class][:covered] << current_function
        covered_functions += 1
      else
        @per_class_coverage[current_class][:not_covered] << current_function
      end
      all_functions += 1
    end

    @total_coverage = covered_functions.to_f/all_functions.to_f * 100.0

    @per_class_coverage.each_key do |k|
      covered = @per_class_coverage[k][:covered].length
      all = @per_class_coverage[k][:covered].length +
            @per_class_coverage[k][:not_covered].length
    end

    # create the html page holding the coverage data
    create_coverage_data_html
  end


  # This function creates the full list of functions that need to be
  # covered from the golden file Google_SketchUp_Ruby_Methods.csv and
  # stores the list in the hash @full_functions_list.
  # Args:
  #   - None
  #
  # Returns:
  #   - None
  def create_cov_lists
    function_list_file = File.join(@coverage_dir_path,
                                   'Google_SketchUp_Ruby_Methods.csv')
    cov_fun_list = File.open(function_list_file, 'r')
    lines = cov_fun_list.readlines()
    lines.each do |l|
      l.rstrip!
      parts = l.split('.')
      @full_functions_list[l] = { :covered => false, :tests => 0,
                                  :class => parts[0], :function => parts[1] }
      if not @per_class_coverage.has_key?(parts[0])
        @per_class_coverage[parts[0]] = {:covered => [], :not_covered => []}
      end
    end
  end

  # This function takes a long name and returns a shortened version of it
  # which is easier to match.
  #
  # Args:
  # - long_name: the string containing the full test_function_etc_etc name.
  #
  # Returns:
  # - short_name : the cleaner string containing the name.
  #
  def function_name(long_name)
    short_name = long_name.gsub('test_', '')

    # Some more cleanup here, which is not necessary
    # but makes the matching a little easier.
    if short_name.include?('_api_example')
      p = short_name.split('_api_example')
      shortm_name = p[0]
    elsif short_name.include?('_true_and_false')
      p = short_name.split('_true_and_false')
      short_name = p[0]
    elsif short_name.include?('_when')
      p = short_name.split('_when')
      short_name = p[0]
    elsif short_name.include?('_simple')
      p = short_name.split('_simple')
      short_name = p[0]
    elsif short_name.include?('_edgecases')
      p = short_name.split('_edgecases')
      short_name = p[0]
    elsif short_name.include?('_known_case')
      p = short_name.split('_known_case')
      short_name = p[0]
    elsif short_name.include?('_zero')
      p = short_name.split('_zero')
      short_name = p[0]
    end

    return short_name
  end

  # This function creates the html page containing total coverage and detailed
  # per class coverage information.
  #
  # Args:
  # - long_name: the string containing the full test_function_etc_etc name.
  #
  # Returns:
  # - short_name : the cleaner string containing the name.
  #
  def create_coverage_data_html
    # useful html formatting elements
    doc_start = "<html><head><meta http-equiv=\"Content-Type\" " +
      "content=\"text/html; charset=utf-8\"></head>\n<style>" +
      "body { font-family: sans-serif; }" +
      "table {\n" +
      "  padding: 0px;\n" +
      "  margin: 0px;\n" +
      "  empty-cells: show;\n" +
      "  border-right: 1px solid silver;\n" +
      "  border-bottom: 1px solid silver;\n" +
      "  border-collapse: collapse;\n" +
      "}\n" +
      "td {\n" +
      "  padding: 4px;\n" +
      "  margin: 0px;\n" +
      "  border-left: 1px solid silver;\n" +
      "  border-top: 1px solid silver;\n" +
      "  font-family: sans-serif;\n" +
      "  font-size: 9pt;\n" +
      "  vertical-align: top;\n" +
      "}\n</style>\n" +
      "<table border=1 width=100%>"
    doc_end    = "</table></html>"
    row_start  = "   <tr>\n"
    row_end    = "   </tr>\n"
    cell_start = "    <td>"
    cell_mid   = "</td>\n    <td>"
    cell_end   = "</td>\n"
    endline = "</br>"
    green = '<span style="background-color:green">'
    yellow = '<span style="background-color:yellow">'
    red = '<span style="background-color:red">'
    endspan = "</span>"
    bold = "<b>"
    end_bold = "</b>"
    italic = "<i>"
    end_italic = "</i>"
    non_breakable_space = "&nbsp; &nbsp; &nbsp;"
    cov_html = File.join(@coverage_dir_path, 'testup_coverage.html')
    out_html = File.new(cov_html, 'w+')
    out_html.write(doc_start)

    out_html.write("<big>Google SketchUp Ruby Unit Test Coverage</big>" +
                   endline)
    out_html.write("#{row_start} #{bold}The total amount of coverage is: " +
                   "%.2f" % @total_coverage + "% " + end_bold + row_end +
                   endline + endline)


    # This step ensures that the classes are written out in alphabetical order
    # The classes are in the keys of teh @per_class_coverage Hash.
    sorted_classes = @per_class_coverage.keys.sort

    sorted_classes.each do |k|
      covered = @per_class_coverage[k][:covered].length
      all = @per_class_coverage[k][:covered].length +
            @per_class_coverage[k][:not_covered].length
      current_class_cov = (covered.to_f/all.to_f) * 100
      str = "<tr><td colspan=2><hr></td></tr>" + row_start + cell_start +
            "#{bold}Class " + k + "#{end_bold}" + cell_mid

      # color according to coverage
      if current_class_cov == 0
        str += red
      elsif current_class_cov > 0 and current_class_cov < 100
        str += yellow
      else
        str += green
      end
      str += "%.2f" % current_class_cov + "%" + endspan + " coverage" +
              cell_end + row_end
      out_html.write(str)

      cov_functions = row_start + cell_start + "covered functions are: "
      @per_class_coverage[k][:covered].each do |f|
        test_cases = @full_functions_list["#{k}.#{f}"][:tests]
        if test_cases == 1
          cov_functions += "#{endline}#{non_breakable_space}#{italic}#{f}" +
                           "#{end_italic} with #{test_cases} test"
        else
          cov_functions += "#{endline}#{non_breakable_space}#{italic}#{f}" +
                           "#{end_italic} with #{test_cases} tests"
        end
      end
      cov_functions += cell_end + row_end
      out_html.write(cov_functions)

      non_cov_functions = row_start + cell_start +
                          "non covered functions are: "

      @per_class_coverage[k][:not_covered].each do |f|
        non_cov_functions += "#{endline}#{non_breakable_space}" +
                             "#{italic}#{f}#{end_italic} "
      end
      non_cov_functions += cell_end + row_end
      out_html.write(non_cov_functions)

    end

    out_html.write(doc_end)
    out_html.close
  end

end
