#!/usr/bin/ruby
#
# Copyright:: Copyright 2012 Trimble Navigation Ltd.
# License:: Apache License version 2.0
# Original Author:: Simone Nicolo 
#
# Regression test for Buganizer Bug #2406279.
#


require 'test/unit'

# The main test class.

class TC_2406279 < Test::Unit::TestCase
  def test_2406279
    local_path = __FILE__.slice(0, __FILE__.rindex('.'))
    my_test_asset = File.join(local_path, 'no_authoring_tool_tag.dae')
    
    m = Sketchup.active_model
    ents = m.entities
    # Start fresh...
    ents.clear!
    
    status = Sketchup.active_model.import my_test_asset

    assert_equal(status, true, 'associated buganizer bug is 2406279')
  end
end
