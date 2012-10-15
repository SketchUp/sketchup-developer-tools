#!/usr/bin/ruby
#
# Original Author:: <your name>
#
# <bug description here>
#


require 'test/unit'

# The main test class.
#
# This is what will be run automatically by TestUp. Make sure that your class
# name is exactly the same as your file name (minus the .rb extension). For bug
# regression tests, just replace _BUG_NUMBER in the file name, class name, and
# test_ method with the Buganizer bug number. For example, the test case for bug
# id 12345678 should be in a file named TC_12345678.rb, with a test class named
# TC_12345678 and a test method named test_12345678.
#
class TC_NEW_BUG < Test::Unit::TestCase
  def test_NEW_BUG
    # Optional:
    # Local path for opening or importing test assets. Create a directory
    # with the same name as your test case file (minus the .rb extension of
    # course) and place any auxillary files in it. Then uncomment the second
    # line and replace ASSET_NAME to get a full path to your test asset.
    local_path = __FILE__.slice(0, __FILE__.rindex('.'))
    #my_test_asset = File.join(local_path, 'ASSET_NAME')
    
    # Convenience: Most tests need this.
    m = Sketchup.active_model
    ents = m.entities
    # Start fresh...
    ents.clear!
    
    # Required: Make sure to assert a condition to pass/fail the test.
    assert_equal(1, 1, 'description of expectation here')
  end
end
