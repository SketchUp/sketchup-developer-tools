#!/usr/bin/ruby
#
# Copyright:: Copyright 2012 Trimble Navigation Ltd.
# License:: Apache License version 2.0
# Original Author:: Matt Lowrie 
#
# Regression test for Buganizer Bug #1577568.
#


require 'test/unit'

class TC_1577568 < Test::Unit::TestCase
  def test_1577568
    m = Sketchup.active_model
    ents = m.entities
    # Start fresh...
    ents.clear!

    # Tilt up the camera so the bug is visible in the SketchUp viewport
    eye = [-239.931, -265.381, 238.686]
    target = [348.022, 354.183, -210.664]
    up = [0, 0, 1]
    m.active_view.camera = Sketchup::Camera.new eye, target, up

    # Make the initial shape
    pt1 = [0, 0, 0]
    pt2 = [100, 0, 0]
    pt3 = [100, 100, 0]
    pt4 = [0, 100, 0]
    base = ents.add_face [pt1, pt2, pt3, pt4]
    height = 50
    height = (height * -1) if base.normal.dot(Z_AXIS) < 0
    base.pushpull height

    # Find the extrude edge
    extrude_edge = nil
    ents.each do |e|
      if e.class == Sketchup::Edge
        vrt1 = [0, 0, 50]
        vrt2 = [100, 0, 50]
        if e.start.position == vrt1 or e.start.position == vrt2
          if e.end.position == vrt1 or e.end.position == vrt2
            extrude_edge = e
          end
        end
      end
    end

    # Create the face that will be extruded
    created_edge = ents.add_line [[0, 0, 0], [0, 25, 50]]

    # This new edge created a triangle, so find that face
    follow_me_face = nil
    created_edge.faces.each do |f|
      follow_me_face = f if f.edges.length == 3
    end

    # The test...
    follow_me_face.followme extrude_edge

    # The bug is that this follow me operation leaves and extra face, so make
    # sure the face and edge count is correct after the operation.
    face_count = 0
    edge_count = 0
    ents.each do |e|
      face_count += 1 if e.class == Sketchup::Face
      edge_count += 1 if e.class == Sketchup::Edge
    end
    assert_equal(6, face_count)
    assert_equal(12, edge_count)
  end
end
