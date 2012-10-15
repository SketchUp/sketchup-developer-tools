#!/usr/bin/ruby
#
# Copyright:: Copyright 2012 Trimble Navigation Ltd.
# License:: Apache License version 2.0
# Original Author:: Scott Lininger 
#
# Regression test for Buganizer Bug #5237445
#


require 'test/unit'

# The main test class.
#
#
class TC_5237445 < Test::Unit::TestCase
  def test_5237445
    # Note that since this test is all about loading of files, we
    # can only run it once per SketchUp session. So if this is the
    # second time, we just bail.
    if $test_5237445_ran == true
      raise('This test can only be run once per session. ' +
            'Restart SketchUp and try again.')
      return
    end

    local_path = __FILE__.slice(0, __FILE__.rindex('.'))
    unencrypted_file = File.join(local_path, 'increment.rb')
    unencrypted_file2 = File.join(local_path, 'increment')
    encrypted_file = File.join(local_path, 'increment_encrypted.rbs')
    encrypted_file2 = File.join(local_path, 'increment_ENCRYPTED.rbs')
    encrypted_file3 = File.join(local_path, 'increment_encrypted')

    Sketchup.require(unencrypted_file)
    assert_equal(1, $number_of_times_loaded,
        'require loaded increment.rb once')

    Sketchup.require(unencrypted_file2)
    assert_equal(1, $number_of_times_loaded,
        'require did not load increment.rb again')

    Sketchup.require(unencrypted_file)
    assert_equal(1, $number_of_times_loaded,
        'require did not load increment.rb yet again')

    Sketchup.require(unencrypted_file2)
    assert_equal(1, $number_of_times_loaded,
        'require did not load increment.rb still')

    Sketchup.require(encrypted_file)
    assert_equal(2, $number_of_times_loaded,
        'require rbs loaded once')

    Sketchup.require(encrypted_file2)
    assert_equal(2, $number_of_times_loaded,
        'require rbs did not load again')

    Sketchup.require(encrypted_file)
    assert_equal(2, $number_of_times_loaded,
        'require rbs did not load yet again')

    Sketchup.require(encrypted_file2)
    assert_equal(2, $number_of_times_loaded,
        'require rbs did not load still')

    Sketchup.require(encrypted_file3)
    assert_equal(2, $number_of_times_loaded,
        'require rbs did not load a 3rd time')
    
    $test_5237445_ran = true
  end
end
