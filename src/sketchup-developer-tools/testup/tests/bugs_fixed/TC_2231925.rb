#!/usr/bin/ruby
#
# Copyright:: Copyright 2012 Trimble Navigation Ltd.
# License:: Apache License version 2.0
# Original Author:: Matt Lowrie 
#
# Regression test for Buganizer Bug #2231925
#


require 'test/unit'

# The main test class.
#
class TC_2231925 < Test::Unit::TestCase
  def test_2231925
    assert_nothing_raised do
     point1 = Geom::Point3d.new (0,0,0)
     point2 = Geom::Point3d.new (0,0,100)
     depth = 100
     width = 100
     model = Sketchup.active_model
     entities = model.active_entities
     pts = []
     pts[0] = [0, 0, 0]
     pts[1] = [width, 0, 0]
     pts[2] = [width, depth, 0]
     pts[3] = [0, depth, 0]

     # Add the face to the entities in the model
     face = entities.add_face pts
     line = entities.add_line point1, point2
     status = face.followme line  # This is crashing
     assert_equal(true, status)
    end
  end
end
