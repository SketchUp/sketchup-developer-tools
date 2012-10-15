#!/usr/bin/ruby
#
# Copyright:: Copyright 2012 Trimble Navigation Ltd.
# License:: Apache License version 2.0
# Original Author:: Simone Nicolo 
#
# Regression test for Buganizer Bug #2542651.
#


require 'test/unit'

# The main test class.

class TC_2542651 < Test::Unit::TestCase
  def setup
    local_path = __FILE__.slice(0, __FILE__.rindex('.'))

    m = Sketchup.active_model
    ents = m.entities
    # Start fresh...
    ents.clear!
    @msg = 'Failure, bug is: <a href="http://b/issue?id=2542651">2542651</a>'
  end

  def helper_function
    $et = (Time.now - $t)
    puts 'et=' + $et.to_s
  end

  def test_2542651
    $t = Time.now
    UI.start_timer(0.4, false) {helper_function}
    # If the difference is less than 1/100th we call it good
    assert_equal(true, (($et.to_f - 0.4) < 0.01), @msg)
  end
end
