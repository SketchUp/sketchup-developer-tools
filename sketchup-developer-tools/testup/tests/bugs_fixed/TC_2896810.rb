#!/usr/bin/ruby
#
# Copyright:: Copyright 2012 Trimble Navigation Ltd.
# License:: Apache License version 2.0
# Original Author:: Scott Lininger 
#
# Regression test for Buganizer Bug #2896810.
#


require 'test/unit'

# The main test class.
#
class TC_2896810 < Test::Unit::TestCase
  def test_2896810
    v1 = X_AXIS.clone
    v2 = X_AXIS.reverse.clone
    v1.length = 0.1.mm
    v2.length = 0.1.mm
    value = v1.angle_between v2
    assert_equal(Math::PI, value,
                 'Failed in test_2896810' )
  end
end
