#!/usr/bin/ruby
#
# Copyright:: Copyright 2012 Trimble Navigation Ltd.
# License:: Apache License version 2.0
# Original Author:: Matt Lowrie 
#
# Regression test for Buganizer Bug #1486690.
#


require 'test/unit'

# The main test class.
#
class TC_1486690 < Test::Unit::TestCase
  def test_1486690
    # Convenience: Most tests need this.
    m = Sketchup.active_model
    ents = m.entities
    # Start fresh...
    ents.clear!

    # Add a face and get a handle to it
    ents.add_face [0, 0, 0], [0, 10, 0], [10, 10, 0], [10, 0, 0]
    the_face = nil
    ents.each { |e| the_face = e if e.is_a? Sketchup::Face }

    uv_help = the_face.get_UVHelper  # This will crash
    assert(uv_help.is_a?(Sketchup::UVHelper))
  end
end
