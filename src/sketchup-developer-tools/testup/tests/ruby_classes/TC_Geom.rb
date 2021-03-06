# Copyright:: Copyright 2012 Trimble Navigation Ltd.
# License:: Apache License version 2.0
# Original Author:: Scott Lininger 
#
# Tests the SketchUp Ruby API Geom object.
#
# This file was originally generated by ourdoc.rb, an internal tool we developed
# specifically for outputting support files (documentation, unit tests, etc.)
# from the standard, doxygen-style c++ comments that are embedded into the
# Ruby implementation files. You can find ourdoc.rb alongside these
# implementation files at:
#
# googleclient/sketchup/source/sketchup/ruby
#

require 'test/unit'

# TC_Geom contains unit tests for the Geom class.
#
# API Object::       Geom
# C++ File::         rgeom.cpp
# Parent Class::     N/A
# Version::          SketchUp 6.0
#
# The Geom module defines a number of Module methods that let you perform
# different geometric operations.
#
# The methods in this module take lines
# and planes as arguments. There is no special class for representing lines or
# planes.
#
# A line can be represented as either an Array of a point and a
# vector, or as an Array of two points.
#     line = [Geom::Point3d.new(0,0,0),
#     Geom::Vector3d.new(0,0,1)]
#     line = [Geom::Point3d.new(0,0,0),
#     Geom::Point3d.new(0,0,100)]
#
# A plane can be represented as either an Array
# of a point and a vector, or as an Array of 4 numbers that given the
# coefficients of a plane equation.
#     plane = [Geom::Point3d.new(0,0,0),
#     Geom::Vector3d.new(0,0,1)]
#     plane = [0,0,1,0]
#
# NOTE: Lines and Planes are infinite.
#
# There are several good books on 3D math if you are new to
# the concepts of a line, plane, and vector.
#
#
class TC_Geom < Test::Unit::TestCase

  # Setup for test cases, if required.
  #
  def setup
    def UI::messagebox(params)
      puts 'TESTUP OVERRIDE: UI::messagebox > ' + params.to_s
    end
  end

  # ----------------------------------------------------------------------------
  # @par Ruby Method:    Geom.intersect_plane_plane
  # @file                rgeom.cpp
  #
  # The intersect_plane_plane method is used to compute the intersection
  # of two planes.
  #
  #
  # Args:
  # - plane1,: plane2 Planes.
  #
  # Returns:
  # - line: a line where the planes intersect if successful.
  # Returns nil if the planes do not intersect.
  #

  # Test the example code that we have in the API documentation.
  def test_intersect_plane_plane_api_example
    assert_nothing_raised do
     # This is really the normal which follows the x axis. The plane is
     # perpendicular (or parallel to the Y axis)
     plane1 = [Geom::Point3d.new(-10, 0 ,0), Geom::Vector3d.new(1,0,0)]
     # This is really the normal which follows the y axis. The plane is
     # perpendicular (or parallel to the X axis)
     plane2 = [Geom::Point3d.new(0,-10,0), Geom::Vector3d.new(0,1,0)]
     # returns (-10,-10,0")(0.0,0.0,1.0)
     line = Geom.intersect_plane_plane(plane1, plane2)
    end
  end

  # Test edgecases for values passed to this method.
  #def test_intersect_plane_plane_edgecases
  #  raise('AUTOGENERATED STUB. Do manual review, then delete this warning.')
  #  assert_equal('expected', 'result',
  #               'Failed in test_intersect_plane_plane_edgecases' )
  #end

  # Test what happens when bad arguments are passed (nil, too few, etc.)
  #def test_intersect_plane_plane_bad_params
  #  raise('AUTOGENERATED STUB. Do manual review, then delete this warning.')
  #  assert_raise RuntimeError do
  #    # bad arguments here that should cause errors
  #  end
  #end

  # ----------------------------------------------------------------------------
  # @par Ruby Method:    Geom.linear_combination
  # @file                rgeom.cpp
  #
  # The linear_combination method is used to compute the linear
  # combination of points or vectors.
  #
  #
  #
  # Args:
  # - weight1: A weight or percentage.
  # - point1: The start point on the line.
  # - weight2: A weight or percentage.
  # - point2: The end point of the line.
  # - vector1: The first vector.
  # - vector2: The end point of the line.
  #
  # Returns:
  # - point: point - a Point3d object vector - vector - a
  # Vector3d object
  #

  # Test the example code that we have in the API documentation.
  def test_linear_combination_api_example
    assert_nothing_raised do
     point1 = Geom::Point3d.new 1,1,1
     point2 = Geom::Point3d.new 10,10,10
     # Gets the point on the line segment connecting point1 and point2 that is
     # 3/4 the way from point1 to point2.
     point = Geom.linear_combination 0.25, point1, 0.75, point2
    end
  end

  # Test edgecases for values passed to this method.
  #def test_linear_combination_edgecases
  #  raise('AUTOGENERATED STUB. Do manual review, then delete this warning.')
  #  assert_equal('expected', 'result',
  #               'Failed in test_linear_combination_edgecases' )
  #end

  # Test what happens when bad arguments are passed (nil, too few, etc.)
  #def test_linear_combination_bad_params
  #  raise('AUTOGENERATED STUB. Do manual review, then delete this warning.')
  #  assert_raise RuntimeError do
  #    # bad arguments here that should cause errors
  #  end
  #end

  # ----------------------------------------------------------------------------
  # @par Ruby Method:    Geom.fit_plane_to_points
  # @file                rgeom.cpp
  #
  # The fit_plane_to_points method is used to compute a plane that is a
  # best fit to an array of points
  #
  # If more than three points are given, some of the points may not be on
  # the plane. The plane is returned as an Array of 4 numbers which are
  # the coefficients of the plane equation Ax + By + Cz + D = 0
  #
  #
  # Args:
  # - points: An array of points.
  # - point1,: point2, point3 Point3D objects.
  #
  # Returns:
  # - plane: a plane
  #

  # Test the example code that we have in the API documentation.
  def test_fit_plane_to_points_api_example
    assert_nothing_raised do
     point1 = Geom::Point3d.new 0,0,0
     point2 = Geom::Point3d.new 10,10,10
     point3 = Geom::Point3d.new 25,25,25
     plane = Geom.fit_plane_to_points point1, point2, point3
    end
  end

  # Test edgecases for values passed to this method.
  #def test_fit_plane_to_points_edgecases
  #  raise('AUTOGENERATED STUB. Do manual review, then delete this warning.')
  #  assert_equal('expected', 'result',
  #               'Failed in test_fit_plane_to_points_edgecases' )
  #end

  # Test what happens when bad arguments are passed (nil, too few, etc.)
  #def test_fit_plane_to_points_bad_params
  #  raise('AUTOGENERATED STUB. Do manual review, then delete this warning.')
  #  assert_raise RuntimeError do
  #    # bad arguments here that should cause errors
  #  end
  #end

  # ----------------------------------------------------------------------------
  # @par Ruby Method:    Geom.closest_points
  # @file                rgeom.cpp
  #
  # The closest_points method is used to compute the closest points on two
  # lines.
  #
  #
  # Args:
  #
  # Returns:
  # - pts: an array of two points. The first point is on the
  # first line and the second point is on the second line.
  #

  # Test the example code that we have in the API documentation.
  def test_closest_points_api_example
    assert_nothing_raised do
     line1 = [Geom::Point3d.new(0,0,0), Geom::Vector3d.new(0,0,1)]
     line2 = [Geom::Point3d.new(0,0,0), Geom::Vector3d.new(0,0,100)]
     # 0,0,0 on each line should be closest because both lines start from
     # that point
     pts = Geom.closest_points line1, line2
    end
  end

  # Test edgecases for values passed to this method.
  #def test_closest_points_edgecases
  #  raise('AUTOGENERATED STUB. Do manual review, then delete this warning.')
  #  assert_equal('expected', 'result',
  #               'Failed in test_closest_points_edgecases' )
  #end

  # Test what happens when bad arguments are passed (nil, too few, etc.)
  #def test_closest_points_bad_params
  #  raise('AUTOGENERATED STUB. Do manual review, then delete this warning.')
  #  assert_raise RuntimeError do
  #    # bad arguments here that should cause errors
  #  end
  #end

  # ----------------------------------------------------------------------------
  # @par Ruby Method:    Geom.intersect_line_line
  # @file                rgeom.cpp
  #
  # The intersect_line_line computes the intersection of two lines.
  #
  #
  # Args:
  # - line1,: line2 A line is given as either an array of a point and a
  # vector, or an Array or two points.
  #
  # Returns:
  # - : Returns nil if they do not intersect.
  #

  # Test the example code that we have in the API documentation.
  def test_intersect_line_line_api_example
    assert_nothing_raised do
     line1=[Geom::Point3d.new(10,0,0),Geom::Vector3d.new(1,0,0)]
     line2=[Geom::Point3d.new(0,10,0),Geom::Point3d.new(20,10,0)]
     pt = Geom.intersect_line_line(line1, line2)
     # This will return the point (10,10,0).
    end
  end

  # Test edgecases for values passed to this method.
  #def test_intersect_line_line_edgecases
  #  raise('AUTOGENERATED STUB. Do manual review, then delete this warning.')
  #  assert_equal('expected', 'result',
  #               'Failed in test_intersect_line_line_edgecases' )
  #end

  # Test what happens when bad arguments are passed (nil, too few, etc.)
  #def test_intersect_line_line_bad_params
  #  raise('AUTOGENERATED STUB. Do manual review, then delete this warning.')
  #  assert_raise RuntimeError do
  #    # bad arguments here that should cause errors
  #  end
  #end

  # ----------------------------------------------------------------------------
  # @par Ruby Method:    Geom.intersect_line_plane
  # @file                rgeom.cpp
  #
  # The intersect_line_plane method is used to compute the intersection of
  # a line and a plane.
  #
  #
  #
  # Args:
  # - line: A line.
  # - plane: A plane.
  #
  # Returns:
  # - point: a Point3d object
  #

  # Test the example code that we have in the API documentation.
  def test_intersect_line_plane_api_example
    assert_nothing_raised do
     # This is really the normal which follows the x axis. The plane is
     # perpendicular
     plane1 = [Geom::Point3d.new(-10, 0 ,0), Geom::Vector3d.new(1,0,0)]

     # This line follows the x axis
     line1 = [Geom::Point3d.new(-10,0,0), Geom::Vector3d.new(1,0,0)]

     # returns -10, 0, 0
     pt = Geom.intersect_line_plane(line1, plane1)
    end
  end

  # Test edgecases for values passed to this method.
  #def test_intersect_line_plane_edgecases
  #  raise('AUTOGENERATED STUB. Do manual review, then delete this warning.')
  #  assert_equal('expected', 'result',
  #               'Failed in test_intersect_line_plane_edgecases' )
  #end

  # Test what happens when bad arguments are passed (nil, too few, etc.)
  #def test_intersect_line_plane_bad_params
  #  raise('AUTOGENERATED STUB. Do manual review, then delete this warning.')
  #  assert_raise RuntimeError do
  #    # bad arguments here that should cause errors
  #  end
  #end

  # ----------------------------------------------------------------------------
  # @par Ruby Method:    Geom.point_in_polygon_2D
  # @file                rgeom.cpp
  #
  # The point_in_polygon_2D method is used to determine whether a point is
  # inside a polygon. The z component of both the point you're checking and
  # the points in the polygon are ignored, effectively making it a 2-d check.
  #
  #
  # Args:
  # - point:        A Point3d object
  # - polygon_pts:  An array of points that represent the corners of the polygon
  #                 you are checking against.
  # - check_border: Boolean. Pass true if a point on the border should be
  #                 counted as inside the polygon.
  #
  # Returns:
  # - status: true if the point is inside the polygon.
  #

  # Test the example code that we have in the API documentation.
  def test_point_in_polygon_2d_api_example
    # Create a point that we want to check. (Note that the 3rd coordinate,
    # the z, is ignored for purposes of the check.)
    pt = [5,0,10]

    # Create a series of points of a triangle we want to check against.
    triangle = []
    triangle.push [0,0,0]
    triangle.push [10,0,0]
    triangle.push [0,10,0]

    # Test to see if our point is inside the triangle, counting hits on
    # the border as an intersection in this case.
    hits_on_border_count = true
    assert_nothing_raised do
      status = Geom.point_in_polygon_2D(pt, triangle, hits_on_border_count)
    end
  end

end
