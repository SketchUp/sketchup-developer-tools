#!/usr/bin/ruby
#
# Copyright:: Copyright 2012 Trimble Navigation Ltd.
# License:: Apache License version 2.0
# Original Author:: Simone Nicolo 
#
# Regression test for Buganizer Bug #2225677.

require 'test/unit'

class TC_2225677 < Test::Unit::TestCase
  # Tests the .samedirection? method for the attached model
  def FacesCoplanar(face1, face2)
    pts = []
    vertices = face1.vertices
    vertices.each do |v|
      pts << v.position
    end
    vertices = face2.vertices
    vertices.each do |v|
      pts << v.position
    end
    plane = Geom.fit_plane_to_points pts
  
    pts.each do |pt|
      if not pt.on_plane? plane
        return false
      end
    end
    return true
  end
    
  def test_2225677
    local_path = __FILE__.slice(0, __FILE__.rindex('.'))
    test_model_path = File.join(local_path, 'TC_2225677.skp')

    # Open the model for this test
    Sketchup.open_file test_model_path

    # Grab the entities for the model
    skp = Sketchup.active_model
    entities = skp.active_entities

    # Get all the edges and collect the ones that are bounded by coplanar faces
    c = []
    entities.each do |e|
      if e.is_a?(Sketchup::Edge) and e.faces.length == 2
        if FacesCoplanar(e.faces[0], e.faces[1])
          c << e
        end
      end
    end
    puts c.length
    assert_equal(21, c.length,
      'The edges to erase should be 21 and not ' + c.length.to_s + ' . The ' +
      'associated buganizer bug is 2225677')
    end
end
