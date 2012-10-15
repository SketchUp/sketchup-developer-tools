#-----------------------------------------------------------------------------
#
# Copyright:: Copyright 2012 Trimble Navigation Ltd.
# License:: Apache License version 2.0
# Original Author:: Simone Nicolo 
#
# Tests the SketchUp Break Edges Feature
# This group of tests targets 2D intersecting geometries
#
# NOTE: remember that all this tests relies on the SketchUp Ruby API, which
# might not be perfectly in sync with the actual SketchUp behavior.
#-----------------------------------------------------------------------------

require 'sketchup.rb'
require 'test/unit'

# Test class for Break Edges.
#
#  This class contains several test cases for the newly added Break Edges
#  feature to SU7. All the test cases in this class are targeted at verifying
#  that two-dimensional intersections correctly trigger Break Edges.
#
#  NOTE: Because of bug 1080589 (http://b/issue?id=1080589) break edges is not
#  triggered by simply using Ruby, so the workaround is to put geometry in
#  two groups and explode them which then cause MergeController and therefore
#  BreakEdges to kick in. Tests which name contains the string 'exploding_'
#  are tests that use this workaround. The other tests rely on Ruby geometry
#  creation not triggering break edges, and will need to be modifyied when
#  bug 1080589 is fixed.
#
class TC_BreakEdges2D < Test::Unit::TestCase

  # Function used to set up some class variables.
  #
  # Args:
  #   None
  # Returns:
  #   None
  #
  def setup
    #useful counters
    @nr_edges = 0
    @nr_faces = 0
    @expected_faces = 0
    @expected_edges = 0

    #error messages
    @fail_msg_edges = "The number of edges is NOT correct," +
                      "edges have been incorrectly broken!!!"
    @fail_msg_faces = "The number of faces is NOT correct," +
                      "faces have been incorrectly created!!!"

    @current_test = "BreakEdges:"
  end


  # This function cleans up all the entities in the model,
  # It is used before starting a new test to make sure we have a
  # clean test environment.
  #
  # Args:
  #   None
  # Returns:
  #   None
  #
  def tabula_rasa
    model = Sketchup.active_model
    model.entities.clear!
  end


  # This is the main verification function.
  # It counts Faces and Edges, verifies that the number of created faces
  # and edges are correct.
  #
  # Args:
  #   None
  # Returns:
  #   Trows a failed assertion when either of the numbers of expected faces
  #   or edges are incorrect.
  def verify_faces_and_edges

    @nr_edges = 0
    @nr_faces = 0

    #count faces and edges
    model = Sketchup.active_model
    model.entities.each {|e|

      type = e.typename
      case type
      when "Edge"
        @nr_edges += 1
      when "Face"
        @nr_faces += 1
      else
        # do nothing
        # puts "type is: " + type.to_s # debug info
      end
    }
    # debug info
    #UI.messagebox( "Faces are: #{@nr_faces}; Edges are: #{@nr_edges};
    #                 Expected Edges are: #{@expected_edges};

    #                 Expected Faces are: #{@expected_faces}" )

    assert_equal( [@expected_edges, @expected_faces], [@nr_edges, @nr_faces],
                   @current_test + "\nThe expected faces are #{@expected_faces}
                   and the actual faces are #{@nr_faces}
                   The expected edges are #{@expected_edges}
                   and the actual edges are #{@nr_edges}")
  end


  # Test that, for intersecting rectangles, Break Edges works and
  # that the resulting numbers of faces and edges are correct.
  #
  # Args:
  #   None
  # Returns:
  #   None
  def test_exploding_intersecting_rectangles
      @current_test += "intersecting_rectangles"

      assert_nothing_raised do

       #delete everything in the model
       tabula_rasa

       #dimensions default values
       values = [6.feet, 5.feet]
       width, depth = values

       #get the active model
       model = Sketchup.active_model
       model.start_operation $exStrings.GetString("Create First Rectangle")
       entities = model.active_entities

       rect_1 = entities.add_group

       #create parallelogram 1
       pts_1 = []
       pts_1[0] = [2.feet, 2.feet, 0]
       pts_1[1] = [width + 2.feet, 2.feet, 0]
       pts_1[2] = [width + 2.feet, depth + 2.feet, 0]
       pts_1[3] = [2.feet, depth + 2.feet, 0]

       #create the face
       base_1 = rect_1.entities.add_face pts_1

       # commit and count faces and edges
       model.commit_operation
       @expected_faces = 1
       @expected_edges = 4
       rect_1.explode
       verify_faces_and_edges

       model.start_operation $exStrings.GetString("Create Second Rectangle")

       #create the second intersecting parallelogram
       rect_2 = entities.add_group

       pts_2 = []
       pts_2[0] = [0, 0, 0]
       pts_2[1] = [width, 0, 0]
       pts_2[2] = [width, depth, 0]
       pts_2[3] = [0, depth, 0]

       base_2 = rect_2.entities.add_face pts_2

       # Now we are done and we can commit the creation
       # of the second rectangle
       model.commit_operation
       rect_2.explode

       @expected_faces = 3
       @expected_edges = 12
       verify_faces_and_edges
     end
  end


  # Test that, for intersecting circles, Break Edges works
  # and that the resulting numbers of faces and edges are correct.
  #
  # Args:
  #   None
  # Returns:
  #   None
  def test_exploding_intersecting_circles
    @current_test += "intersecting_circles"
    assert_nothing_raised do

      #delete everything in the model
      tabula_rasa

      #vector parallel to the z axis
      vector = Geom::Vector3d.new 0,0,1
      vector2 = vector.normalize!

      #get the active model
      model = Sketchup.active_model
      model.start_operation $exStrings.GetString("Create First circle")
      entities = model.active_entities

      #define the center point and radius
      center1 =  Geom::Point3d.new(0,0,0)
      radius1 = 3.feet
      circ_1 = entities.add_group

      circle1 = circ_1.entities.add_circle center1, vector2, radius1, 50
      circ_1.entities.add_face circle1

      # commit and count faces and edges
      model.commit_operation
      @expected_faces = 1
      @expected_edges = 50
      circ_1.explode
      verify_faces_and_edges

      model.start_operation $exStrings.GetString("Create Second circle")
      center2 =  Geom::Point3d.new(1.feet, 1.feet, 0)
      radius2 = 2.feet
      circ_2 = entities.add_group

      #define the center point and radius
      circle2 = circ_2.entities.add_circle center2, vector2, radius2, 100
      circ_2.entities.add_face circle2

      # commit and count faces and edges
      model.commit_operation
      @expected_faces = 3
      @expected_edges = 154
      circ_2.explode
      verify_faces_and_edges

    end
  end

  # Test that, for intersecting triangles, Break Edges works and
  # that the resulting numbers of faces and edges are correct.
  # Args:
  #   None
  # Returns:
  #   None
  def test_exploding_intersecting_triangles
    @current_test += "intersecting_triangles"
    assert_nothing_raised do

      #delete everything in the model
      tabula_rasa

      #vector parallel to the z axis
      vector = Geom::Vector3d.new 0,0,1
      vector2 = vector.normalize!

      #get the active model
      model = Sketchup.active_model
      model.start_operation $exStrings.GetString("Create First triangle")
      entities = model.active_entities

      #define the center point and radius
      center1 =  Geom::Point3d.new(0,0,0)
      radius1 = 3.feet

      triangle_1 = entities.add_group

      circle1 = triangle_1.entities.add_circle center1, vector2, radius1, 3
      triangle_1.entities.add_face circle1

      # commit and count faces and edges
      model.commit_operation
      @expected_faces = 1
      @expected_edges = 3
      triangle_1.explode
      verify_faces_and_edges

      model.start_operation $exStrings.GetString("Create Second triangle")
      center2 =  Geom::Point3d.new(1.feet, 1.feet, 0)
      radius2 = 2.feet

      triangle_2 = entities.add_group

      #define the center point and radius
      circle2 = triangle_2.entities.add_circle center2, vector2, radius2, 3
      triangle_2.entities.add_face circle2

      # commit and count faces and edges
      model.commit_operation
      @expected_faces = 3
      @expected_edges = 10
      triangle_2.explode
      verify_faces_and_edges

    end
  end


  # Test that, for intersecting pentagons, Break Edges works and
  # that the resulting numbers of faces and edges are correct.
  # Args:
  #   None
  # Returns:
  #   None
  def test_exploding_intersecting_pentagon
    @current_test += "intersecting_pentagons"
    assert_nothing_raised do

      #delete everything in the model
      tabula_rasa

      #vector parallel to the z axis
      vector = Geom::Vector3d.new 0,0,1
      vector2 = vector.normalize!

      #get the active model
      model = Sketchup.active_model
      model.start_operation $exStrings.GetString("Create First triangle")
      entities = model.active_entities

      #define the center point and radius
      center1 =  Geom::Point3d.new(0,0,0)
      radius1 = 3.feet

      pent_1 = entities.add_group

      circle1 = pent_1.entities.add_circle center1, vector2, radius1, 5
      pent_1.entities.add_face circle1

      # commit and count faces and edges
      model.commit_operation
      @expected_faces = 1
      @expected_edges = 5
      pent_1.explode
      verify_faces_and_edges

      model.start_operation $exStrings.GetString("Create Second triangle")
      center2 =  Geom::Point3d.new(1.feet, 1.feet, 0)
      radius2 = 2.feet

      pent_2 = entities.add_group

      #define the center point and radius
      circle2 = pent_2.entities.add_circle center2, vector2, radius2, 5
      pent_2.entities.add_face circle2

      # commit and count faces and edges
      model.commit_operation
      @expected_faces = 3
      @expected_edges = 14
      pent_2.explode
      verify_faces_and_edges

    end
  end


  # Test that, for intersecting hexagons, Break Edges works and
  # the resulting numbers of faces and edges are correct.
  #
  # Args:
  #   None
  # Returns:
  #   None
  def test_exploding_intersecting_hexagon
     @current_test += "intersecting_hexagons"
     assert_nothing_raised do

      #delete everything in the model
      tabula_rasa

      #vector parallel to the z axis
      vector = Geom::Vector3d.new 0,0,1
      vector2 = vector.normalize!

      #get the active model
      model = Sketchup.active_model
      entities = model.active_entities

      model.start_operation $exStrings.GetString("Create First triangle")
      #define the center point and radius
      center1 =  Geom::Point3d.new(0,0,0)
      radius1 = 3.feet

      hex_1 = entities.add_group

      circle1 = hex_1.entities.add_circle center1, vector2, radius1, 6
      hex_1.entities.add_face circle1

      # commit and count faces and edges
      model.commit_operation
      @expected_faces = 1
      @expected_edges = 6
      hex_1.explode
      verify_faces_and_edges

      model.start_operation $exStrings.GetString("Create Second triangle")
      center2 =  Geom::Point3d.new(1.feet, 1.feet, 0)
      radius2 = 2.feet

      hex_2 = entities.add_group

      #define the center point and radius
      circle2 = hex_2.entities.add_circle center2, vector2, radius2, 6
      hex_2.entities.add_face circle2

      # commit and count faces and edges
      model.commit_operation
      @expected_faces = 3
      @expected_edges = 16
      hex_2.explode
      verify_faces_and_edges

    end
  end

  # Test that when creating a five pointed star using the line tool,
  # Break Edges works correctly.
  #
  # Args:
  #   None
  # Returns:
  #   None
  def test_exploding_star
    @current_test += "intersecting_segments"
    assert_nothing_raised do
      #delete everything in the model
      tabula_rasa

      model = Sketchup.active_model
      entities = model.active_entities
      point1 = Geom::Point3d.new(0,0,0)
      point2 = Geom::Point3d.new(10.feet,8.feet,0)
      point3 = Geom::Point3d.new(16.feet,0,0)
      point4 = Geom::Point3d.new(0,6.feet,0)
      point5 = Geom::Point3d.new(16.feet,8.feet,0)
      point6 = Geom::Point3d.new(0,0,0)

      star = entities.add_group
      model.start_operation $exStrings.GetString("Create Star")
      edges = star.entities.add_edges point1, point2, point3, point4, point5, point6

      model.commit_operation
      @expected_edges = 15
      star.explode
      verify_faces_and_edges

    end
  end



#--------------------------------------------------------------------
# The Test below will pass but will then fail when bug 1080589 is fixed
# (http://b/issue?id=1080589 - Break Edges does not work when intersecting
# geometry are created using the Ruby API)
#--------------------------------------------------------------------



  # Test that, for intersecting rectangles, Break Edges works and
  # that the resulting numbers of faces and edges are correct.
  #
  # Args:
  #   None
  # Returns:
  #   None
  def test_intersecting_rectangles
      @current_test += "intersecting_rectangles"

      assert_nothing_raised do

       #delete everything in the model
       tabula_rasa

       #dimensions default values
       values = [6.feet, 5.feet]
       width, depth = values

       #get the active model
       model = Sketchup.active_model
       model.start_operation $exStrings.GetString("Create First Rectangle")
       entities = model.active_entities

       #create parallelogram 1
       pts_1 = []
       pts_1[0] = [2.feet, 2.feet, 0]
       pts_1[1] = [width + 2.feet, 2.feet, 0]
       pts_1[2] = [width + 2.feet, depth + 2.feet, 0]
       pts_1[3] = [2.feet, depth + 2.feet, 0]

       #create the face
       base_1 = entities.add_face pts_1

       # commit and count faces and edges
       model.commit_operation
       @expected_faces = 1
       @expected_edges = 4
       verify_faces_and_edges

       model.start_operation $exStrings.GetString("Create First Rectangle")

       #create the second intersecting parallelogram
       pts_2 = []
       pts_2[0] = [0, 0, 0]
       pts_2[1] = [width, 0, 0]
       pts_2[2] = [width, depth, 0]
       pts_2[3] = [0, depth, 0]
       base_2 = entities.add_face pts_2

       # Now we are done and we can commit the creation
       # of the second rectangle
       model.commit_operation
       @expected_faces = 2
       @expected_edges = 8
       verify_faces_and_edges
     end
  end



  # Test that, for intersecting circles, Break Edges works
  # and that the resulting numbers of faces and edges are correct.
  #
  # Args:
  #   None
  # Returns:
  #   None
  def test_intersecting_circles
    @current_test += "intersecting_circles"
    assert_nothing_raised do

      #delete everything in the model
      tabula_rasa

      #vector parallel to the z axis
      vector = Geom::Vector3d.new 0,0,1
      vector2 = vector.normalize!

      #get the active model
      model = Sketchup.active_model
      model.start_operation $exStrings.GetString("Create First circle")
      entities = model.active_entities

      #define the center point and radius
      center1 =  Geom::Point3d.new(0,0,0)
      radius1 = 3.feet

      circle1 = entities.add_circle center1, vector2, radius1, 50
      entities.add_face circle1

      # commit and count faces and edges
      model.commit_operation
      @expected_faces = 1
      @expected_edges = 50
      verify_faces_and_edges

      model.start_operation $exStrings.GetString("Create Second circle")
      center2 =  Geom::Point3d.new(1.feet, 1.feet, 0)
      radius2 = 2.feet

      #define the center point and radius
      circle2 = entities.add_circle center2, vector2, radius2, 100
      entities.add_face circle2

      # commit and count faces and edges
      model.commit_operation
      @expected_faces = 2
      @expected_edges = 150
      verify_faces_and_edges

    end
  end


  # Test that, for intersecting triangles, Break Edges works and
  # that the resulting numbers of faces and edges are correct.
  # Args:
  #   None
  # Returns:
  #   None
  def test_intersecting_triangles
    @current_test += "intersecting_triangles"
    assert_nothing_raised do

      #delete everything in the model
      tabula_rasa

      #vector parallel to the z axis
      vector = Geom::Vector3d.new 0,0,1
      vector2 = vector.normalize!

      #get the active model
      model = Sketchup.active_model
      model.start_operation $exStrings.GetString("Create First triangle")
      entities = model.active_entities

      #define the center point and radius
      center1 =  Geom::Point3d.new(0,0,0)
      radius1 = 3.feet

      circle1 = entities.add_circle center1, vector2, radius1, 3
      entities.add_face circle1

      # commit and count faces and edges
      model.commit_operation
      @expected_faces = 1
      @expected_edges = 3
      verify_faces_and_edges

      model.start_operation $exStrings.GetString("Create Second triangle")
      center2 =  Geom::Point3d.new(1.feet, 1.feet, 0)
      radius2 = 2.feet

      #define the center point and radius
      circle2 = entities.add_circle center2, vector2, radius2, 3
      entities.add_face circle2

      # commit and count faces and edges
      model.commit_operation
      @expected_faces = 2
      @expected_edges = 6
      verify_faces_and_edges

    end
  end


  # Test that, for intersecting pentagons, Break Edges works and
  # that the resulting numbers of faces and edges are correct.
  # Args:
  #   None
  # Returns:
  #   None
  def test_intersecting_pentagon
    @current_test += "intersecting_pentagons"
    assert_nothing_raised do

      #delete everything in the model
      tabula_rasa

      #vector parallel to the z axis
      vector = Geom::Vector3d.new 0,0,1
      vector2 = vector.normalize!

      #get the active model
      model = Sketchup.active_model
      model.start_operation $exStrings.GetString("Create First triangle")
      entities = model.active_entities

      #define the center point and radius
      center1 =  Geom::Point3d.new(0,0,0)
      radius1 = 3.feet

      circle1 = entities.add_circle center1, vector2, radius1, 5
      entities.add_face circle1

      # commit and count faces and edges
      model.commit_operation
      @expected_faces = 1
      @expected_edges = 5
      verify_faces_and_edges

      model.start_operation $exStrings.GetString("Create Second triangle")
      center2 =  Geom::Point3d.new(1.feet, 1.feet, 0)
      radius2 = 2.feet

      #define the center point and radius
      circle2 = entities.add_circle center2, vector2, radius2, 5
      entities.add_face circle2

      # commit and count faces and edges
      model.commit_operation
      @expected_faces = 2
      @expected_edges = 10
      verify_faces_and_edges

    end
  end


  # Test that, for intersecting hexagons, Break Edges works and
  # the resulting numbers of faces and edges are correct.
  #
  # Args:
  #   None
  # Returns:
  #   None
  def test_intersecting_hexagon
     @current_test += "intersecting_hexagons"
     assert_nothing_raised do

      #delete everything in the model
      tabula_rasa

      #vector parallel to the z axis
      vector = Geom::Vector3d.new 0,0,1
      vector2 = vector.normalize!

      #get the active model
      model = Sketchup.active_model
      entities = model.active_entities

      model.start_operation $exStrings.GetString("Create First triangle")
      #define the center point and radius
      center1 =  Geom::Point3d.new(0,0,0)
      radius1 = 3.feet

      circle1 = entities.add_circle center1, vector2, radius1, 6
      entities.add_face circle1

      # commit and count faces and edges
      model.commit_operation
      @expected_faces = 1
      @expected_edges = 6
      verify_faces_and_edges

      model.start_operation $exStrings.GetString("Create Second triangle")
      center2 =  Geom::Point3d.new(1.feet, 1.feet, 0)
      radius2 = 2.feet

      #define the center point and radius
      circle2 = entities.add_circle center2, vector2, radius2, 6
      entities.add_face circle2

      # commit and count faces and edges
      model.commit_operation
      @expected_faces = 2
      @expected_edges = 12
      verify_faces_and_edges

    end
  end

  # Test that when creating a five pointed star using the line tool,
  # Break Edges works correctly.
  #
  # Args:
  #   None
  # Returns:
  #   None
  def test_star
    @current_test += "intersecting_segments"
    assert_nothing_raised do
      #delete everything in the model
      tabula_rasa

      model = Sketchup.active_model
      entities = model.active_entities
      point1 = Geom::Point3d.new(0,0,0)
      point2 = Geom::Point3d.new(10.feet,8.feet,0)
      point3 = Geom::Point3d.new(16.feet,0,0)
      point4 = Geom::Point3d.new(0,6.feet,0)
      point5 = Geom::Point3d.new(16.feet,8.feet,0)
      point6 = Geom::Point3d.new(0,0,0)

      model.start_operation $exStrings.GetString("Create Star")
      edges = entities.add_edges point1, point2, point3, point4, point5, point6

      model.commit_operation
      @expected_edges = 5
      verify_faces_and_edges

    end
  end

end
