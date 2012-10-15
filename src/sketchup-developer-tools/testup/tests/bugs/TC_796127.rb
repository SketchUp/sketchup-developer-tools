# Copyright:: Copyright 2012 Trimble Navigation Ltd.
# License:: Apache License version 2.0
# Original Author:: Matt Lowrie 
#
require 'test/unit'

class TC_796127 < Test::Unit::TestCase
  def test_796127_point_to_latlong
    skp = Sketchup.active_model
    skp.entities.clear!
    point = Geom::Point3d.new([10, 10, 10])
    lat_long = skp.point_to_latlong(point)

    fail_msg = 'Model.point_to_latlong did not return a Geom::LatLong ' +
               'object. See bug report <a href="http://b/issue?id=796127">' +
               '796127</a>.'
    assert_equal('Geom::LatLong', lat_long.class.to_s, fail_msg)
  end

  def test_796127_latlong_to_point
    skp = Sketchup.active_model
    skp.entities.clear!
    lat_long = Geom::LatLong.new([50, 100])
    point = skp.latlong_to_point(lat_long)

    fail_msg = 'Model.latlong_to_point() did not return a Geom::Point3d ' +
               'object.'
    assert_equal('Geom::Point3d', point.class.to_s, fail_msg)
  end
end