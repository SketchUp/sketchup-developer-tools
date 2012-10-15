#!/usr/bin/ruby
#
# Original Author:: Scott Lininger
#
# This is an example unit test. It shows a variety of "assertions"
# you can make inside your unit tests.
#


require 'test/unit'

# The main test class. Note that the class MUST be named the same thing as your
# file and inherits from Test::Unit::TestCase.
#
class TC_StandardAsserts < Test::Unit::TestCase
  
  # Any functions you add to your class that begin with test_ will be run as
  # individual test cases. Here's a simple one...
  def test_sketchups_awesomeness
    sketchup = 'awesome'
    desired = 'awesome'
    assert_equal(desired, sketchup, 'SketchUp Rocks!')
  end

  # There's a wide variety of asserts one can call. This test has the common
  # ones, using hard-coded values to definitely pass. Note that the
  # 'Description' param is optional, but it's good practice to define one,
  # because it'll show up in TestUp if there is a failure down the road.
  def test_buncha_asserts
   
    # Assert equality.
    expected_result = 1
    actual_result = 1
    assert_equal(expected_result, actual_result, 'Description.')

    # Assert boolean.
    value = true
    assert(value, 'Description.')

    # Assert nil.
    value = nil
    assert_nil(value, 'Description.')

    # Assert object's class matches something.
    my_array = []
    assert_instance_of(Array, my_array, 'Description.')

    # Assert a block of code does not raise an exception.
    assert_nothing_raised do
      [1, 2].uniq
    end

    # Anyway, you get the idea. If you need something that's not in the
    # list above, look in testup/ruby/test/unit/assertions.rb for 'em all.
  end




end
