# Copyright:: Copyright 2012 Trimble Navigation Ltd.
# License:: Apache License version 2.0
# Original Author:: Scott Lininger 
#
# Tests the SketchUp Ruby API ExtensionsManager object.
#
# googleclient/sketchup/source/sketchup/ruby
#

require 'test/unit'

# TC_ExtensionsManager contains unit tests for the ExtensionsManager class.
#
# API Object::       ExtensionsManager
# C++ File::         rextensionsmanager.cpp
# Parent Class::     Object
# Version::          SketchUp 6.0
#
# The ExtensionsManager class manages various kinds of SketchupExtensions on a
# Model.
#
class TC_ExtensionsManager < Test::Unit::TestCase

  # Setup for test cases, if required.
  #
  def setup
    def UI::messagebox(params)
      puts "TESTUP OVERRIDE: UI::messagebox > #{params.to_s}"
    end
  end

  # ----------------------------------------------------------------------------
  # @par Ruby Method:    Sketchup.extensions
  # @file                rsketchup.cpp
  #
  def test_extensions_api_example
    assert_nothing_raised do
      extensions = Sketchup.extensions
      for extension in extensions
        UI.messagebox('The next extension is named: ' + extension.name +
            ' and its loaded? state is: ' + extension.loaded?.to_s)
      end
    end
  end

  # ----------------------------------------------------------------------------
  # @par Ruby Method:    ExtensionsManager.size
  # @file                rextensionsmanager.cpp
  #
  # The size method returns the number of SketchupExtension objects inside
  # this ExtensionsManager.
  #
  #
  # Args:
  #
  # Returns:
  # - number: number of SketchupExtension objects if successful.
  #

  # Test the example code that we have in the API documentation.
  def test_size_api_example
    manager = nil
    size = nil
    assert_nothing_raised do
     manager = Sketchup.extensions
     size = manager.size
    end
    # The size should be the same as the number of keys
    assert_equal(manager.keys.length, size,
                 'Failed in test_size' )
  end

  # ----------------------------------------------------------------------------
  # @par Ruby Method:    ExtensionsManager.each
  # @file                rextensionsmanager.cpp
  #
  # The each method is used to iterate through extensions.
  #
  #
  # Args:
  # - extension: A variable that will hold each SketchupExtension object
  # as they are found.
  #
  # Returns:
  # - : nil
  #

  # Test the example code that we have in the API documentation.
  def test_each_api_example
    assert_nothing_raised do
     manager = Sketchup.extensions
     # Retrieves each extension
     manager.each { |extension| UI.messagebox extension.name }
    end
  end

  # Test that the number of iterations is equal to the reported length.
  def test_each_iterations_matches_size
    collection = Sketchup.extensions
    count = 0
    collection.each do |obj|
      count = count + 1
    end
    expected = collection.size
    result = count
    assert_equal(expected, result, 'Expected does not match result.')
  end

  # Test that the number of iterations is equal to the reported length.
  def test_each_iterations_matches_count
    collection = Sketchup.extensions
    count = 0
    collection.each do |obj|
      count = count + 1
    end
    expected = collection.count
    result = count
    assert_equal(expected, result, 'Expected does not match result.')
  end

  # Test that the number of iterations is equal to the reported length.
  def test_each_iterations_matches_keys_length
    collection = Sketchup.extensions
    count = 0
    collection.each do |obj|
      count = count + 1
    end
    expected = collection.keys.length
    result = count
    assert_equal(expected, result, 'Expected does not match result.')
  end

  # ----------------------------------------------------------------------------
  # @par Ruby Method:    ExtensionsManager.[]
  # @file                rextensionsmanager.cpp
  #
  #
  #
  # Args:
  # - index: The index of the SketchupExtension object.
  # - name: The name of the SketchupExtension object.
  #
  # Returns:
  # - extension: an SketchupExtension object if
  # successful
  #

  # Test the example code that we have in the API documentation.
  def test_arrayget_api_example
    assert_nothing_raised do
     manager = Sketchup.extensions
     extension = manager[0]
     if (extension)
       UI.messagebox extension
     else
       UI.messagebox "Failure"
     end
    end
  end

  # Test [] operator taking a string and extension doesn't exist.
  def test_ExtensionByName_nonexistant_api_example
    assert_nothing_raised do
     manager = Sketchup.extensions
     result = manager["This Extenstion Does NOT Exist"]
     expected = nil
     assert_equal(expected, result,
                 'Expected does not match result.')
     end
  end

  # Test [] operator taking a string and extension that does exist.
  # Test [] operator taking a string and making sure its case insensitive.
  def test_ExtensionByName_char_case_api_example
    assert_nothing_raised do
     manager = Sketchup.extensions
     expected = manager["Dynamic Components"]
     assert_not_nil(expected, 'Sketchup.extensions["Dynamic Components"] ' +
                   'is nil')
     # Change char case.
     result = manager["dynamic components"]
     assert_equal(expected, result,
                 'Expected does not match result.')
      end
  end

  # Test that nil is returned if there is a negative index requested.
  def bug_test_arrayget_nil_on_negative_index
    collection = Sketchup.extensions
    expected = nil
    result = collection[-1]
    assert_equal(expected, result,
                 'Expected does not match result.')
  end

  # Test that nil is returned if there is a non-existent index requested.
  # We use the length of the collection to our non-existent index.
  def test_arrayget_nil_on_nonexistent_index
    collection = Sketchup.extensions
    expected = nil
    result = collection[collection.count]
    assert_equal(expected, result,
                 'Expected does not match result.')
  end

  def test_arrayget_nil_on_nonexistent_key
    collection = Sketchup.extensions
    expected = nil
    result = collection['KEYTHATWILLNOTEXIST']
    assert_equal(expected, result,
                 'Expected does not match result.')
  end

  def test_arrayget_keys
    collection = Sketchup.extensions
    keys = collection.keys
    for key in keys
      result = collection[key]
      assert_equal('SketchupExtension', result.class.to_s,
                   'Could not look up extension by key: ' + key)
    end
  end

  # ----------------------------------------------------------------------------
  # @par Ruby Method:    ExtensionsManager.keys
  # @file                rextensionsmanager.cpp
  #
  # The keys method is used to get a list of keys in the ExtensionsManager.
  #
  #
  # Args:
  #
  # Returns:
  # - keys: Array of string keys
  #

  # Test the example code that we have in the API documentation.
  def test_keys_api_example
    assert_nothing_raised do
     manager = Sketchup.extensions
     extensionarray = manager.keys
     if (extensionarray)
       UI.messagebox extensionarray
     else
       UI.messagebox "Failure"
     end
    end
  end

  # Test that the entities method returns an Array object.
  def test_keys_returns_array
    obj = Sketchup.extensions
    keys = obj.keys
    result = keys.class
    expected = Array
    assert_equal(expected, result, 'Expected does not match result.')
  end

  # ----------------------------------------------------------------------------
  # @par Ruby Method:    ExtensionsManager.count
  # @file                rextensionsmanager.cpp
  #
  # The count method is an alias for size.
  #
  #
  # Args:
  #
  # Returns:
  # - number: number of SketchupExtension objects if
  # successful
  #

  # Test the example code that we have in the API documentation.
  def test_count_api_example
    manager = nil
    count = nil
    assert_nothing_raised do
     manager = Sketchup.extensions
     count = manager.count
    end
    # The number of keys should match the count
    assert_equal(manager.keys.length, count,
                 'Failed in test_count' )
  end

  # ----------------------------------------------------------------------------
  # @par Ruby Method:    ExtensionsManager.length
  # @file                rextensionsmanager.cpp
  #
  # The length method is an alias for size.
  #
  #
  # Args:
  #
  # Returns:
  # - number: number of SketchupExtension objects if
  # successful
  #

  # Test the example code that we have in the API documentation.
  def test_length_api_example
    manager = nil
    length = nil
    assert_nothing_raised do
     manager = Sketchup.extensions
     length = manager.length
    end
    # The number of keys should match the count
    assert_equal(manager.keys.length, length,
                 'Failed in test_length' )
  end
end
