#-----------------------------------------------------------------------------
#
# Copyright:: Copyright 2012 Trimble Navigation Ltd.
# License:: Apache License version 2.0
# Original Author:: David Vicknair 
# Additional Author:: Simone Nicolo 
#
# Tests the SketchUp boolean operations features
#
# NOTE: remember that all this tests relies on the SketchUp Ruby API, which
# might not be perfectly in sync with the actual SketchUp behavior.
#-----------------------------------------------------------------------------

require 'sketchup.rb'
require 'test/unit'

# Test class for Boolean operations.
#
#  This class contains several test cases for the newly added Solid Tools
#  feature to SU8.
#
class TC_boolean_operations < Test::Unit::TestCase

  def setup
    Sketchup.active_model.entities.clear!
  end

  def test_union1
    # Testing pathological cases: Union one cube face-to-face against a second
    # cube where the shared faces are one against many (4).
    model = Sketchup.active_model
    entities = model.entities
    pts = []
    pts[0] = [0, 0, 0]
    pts[1] = [100, 0, 0]
    pts[2] = [100, 25, 0]
    pts[3] = [100, 50, 0]
    pts[4] = [100, 75, 0]
    pts[5] = [100, 100, 0]
    pts[6] = [0, 100, 0]

    #Test instance.intersect
    definition = model.definitions.add("component")
    # Add the face to the entities in the group
    face = definition.entities.add_face pts
    status = face.pushpull -100, true
    origin = Geom::Point3d.new 0, 0, 0
    transform = Geom::Transformation.new origin
    point = Geom::Point3d.new 100, 0, 0
    t = Geom::Transformation.new point
    golden = entities.add_group

    pts1 = []
    pts1[0] = [0, 0, 0]
    pts1[1] = [200, 0, 0]
    pts1[2] = [200, 100, 0]
    pts1[3] = [0, 100, 0]

    # Add the face to the entities in the group
    face = golden.entities.add_face pts1
    status = face.pushpull -100, true
    instance1 = entities.add_instance definition, transform
    instance2 = instance1.copy
    instance2.move! t
    union = instance1.union(instance2)
    assert(golden.equals?(union), 'instance.union failed')
  end

  def test_union2
    # Testing pathological cases: Union one cube face-to-face against a second
    # cube where the shared faces are many against many (4).
    model = Sketchup.active_model
    entities = model.entities
    pts = []
    pts[0] = [0, 0, 0]
    pts[1] = [100, 0, 0]
    pts[2] = [100, 25, 0]
    pts[3] = [100, 50, 0]
    pts[4] = [100, 75, 0]
    pts[5] = [100, 100, 0]
    pts[6] = [0, 100, 0]
    pts[7] = [0, 75, 0]
    pts[8] = [0, 50, 0]
    pts[9] = [0, 25, 0]

    #Test instance.union
    definition = model.definitions.add("component")
    # Add the face to the entities in the group
    face = definition.entities.add_face pts
    status = face.pushpull -100, true
    origin = Geom::Point3d.new 0, 0, 0
    transform = Geom::Transformation.new origin
    point = Geom::Point3d.new 100, 0, 0
    t = Geom::Transformation.new point
    golden = entities.add_group

    pts1 = []
    pts1[0] = [0, 0, 0]
    pts1[1] = [200, 0, 0]
    pts1[2] = [200, 100, 0]
    pts1[3] = [0, 100, 0]

    # Add the face to the entities in the group
    face = golden.entities.add_face pts1
    status = face.pushpull -100, true
    instance1 = entities.add_instance definition, transform
    instance2 = instance1.copy
    instance2.move! t
    union = instance1.union(instance2)
    assert(golden.equals?(union), 'instance.union failed')
  end

  def test_union3
    # Testing pathological cases: Union one cube face-to-face but offset
    # against a second cube where the shared faces are one against many (4).
    model = Sketchup.active_model
    entities = model.entities
    pts = []
    pts[0] = [0, 0, 0]
    pts[1] = [100, 0, 0]
    pts[2] = [100, 25, 0]
    pts[3] = [100, 50, 0]
    pts[4] = [100, 75, 0]
    pts[5] = [100, 100, 0]
    pts[6] = [0, 100, 0]

    #Test instance.union
    definition = model.definitions.add("component")
    # Add the face to the entities in the group
    face = definition.entities.add_face pts
    status = face.pushpull -100, true
    origin = Geom::Point3d.new 0, 0, 0
    transform = Geom::Transformation.new origin
    point = Geom::Point3d.new 100, 25, 0
    t = Geom::Transformation.new point
    golden = entities.add_group

    pts1 = []
    pts1[0] = [0, 0, 0]
    pts1[1] = [100, 0, 0]
    pts1[2] = [100, 25, 0]
    pts1[3] = [200, 25, 0]
    pts1[4] = [200, 125, 0]
    pts1[5] = [100, 125, 0]
    pts1[6] = [100, 100, 0]
    pts1[7] = [0, 100, 0]

    # Add the face to the entities in the group
    face = golden.entities.add_face pts1
    status = face.pushpull -100, true
    instance1 = entities.add_instance definition, transform
    instance2 = instance1.copy
    instance2.move! t
    union = instance1.union(instance2)
    assert(golden.equals?(union), 'instance.union failed')
  end

  def test_union4
    # Testing pathological cases: Union one cube face-to-face but offset
    # against a second cube where the shared faces are many against many (4).
    model = Sketchup.active_model
    entities = model.entities
    pts = []
    pts[0] = [0, 0, 0]
    pts[1] = [100, 0, 0]
    pts[2] = [100, 25, 0]
    pts[3] = [100, 50, 0]
    pts[4] = [100, 75, 0]
    pts[5] = [100, 100, 0]
    pts[6] = [0, 100, 0]
    pts[7] = [0, 75, 0]
    pts[8] = [0, 50, 0]
    pts[9] = [0, 25, 0]

    #Test instance.union
    definition = model.definitions.add("component")
    # Add the face to the entities in the group
    face = definition.entities.add_face pts
    status = face.pushpull -100, true
    origin = Geom::Point3d.new 0, 0, 0
    transform = Geom::Transformation.new origin
    point = Geom::Point3d.new 100, 25, 0
    t = Geom::Transformation.new point
    golden = entities.add_group

    pts1 = []
    pts1[0] = [0, 0, 0]
    pts1[1] = [100, 0, 0]
    pts1[2] = [100, 25, 0]
    pts1[3] = [200, 25, 0]
    pts1[4] = [200, 125, 0]
    pts1[5] = [100, 125, 0]
    pts1[6] = [100, 100, 0]
    pts1[7] = [0, 100, 0]

    # Add the face to the entities in the group
    face = golden.entities.add_face pts1
    status = face.pushpull -100, true
    instance1 = entities.add_instance definition, transform
    instance2 = instance1.copy
    instance2.move! t
    union = instance1.union(instance2)
    assert(golden.equals?(union), 'instance.union failed')
  end

# Issue here is that the origin of the intersection result, which is a group,
# has a definition of 0,0,0 instead of 0,25,0 and therefore the comparison is
# problematic.

  def test_intersect1
    # Testing pathological cases: Intersect one cube against another offset.
    model = Sketchup.active_model
    entities = model.entities
    pts = []
    pts[0] = [0, 0, 0]
    pts[1] = [100, 0, 0]
    pts[2] = [100, 100, 0]
    pts[3] = [0, 100, 0]

    #Test instance.intersect
    definition = model.definitions.add("component")
    # Add the face to the entities in the group
    face = definition.entities.add_face pts
    status = face.pushpull -100, true

    origin = Geom::Point3d.new 0, 0, 0
    transform = Geom::Transformation.new origin
    point = Geom::Point3d.new 0, 25, 0
    t = Geom::Transformation.new point

    golden = entities.add_group

    pts1 = []
    pts1[0] = [0, 0, 0]
    pts1[1] = [100, 0, 0]
    pts1[2] = [100, 75, 0]
    pts1[3] = [0, 75, 0]

    # Add the face to the entities in the group
    face = golden.entities.add_face pts1

    status = face.pushpull -100, true

    golden.transform! t
    instance1 = entities.add_instance definition, transform
    instance2 = instance1.copy
    instance2.move! t

    intersection = instance1.intersect(instance2)
    assert(golden.equals?(intersection), 'instance.intersect failed')
  end


  def test_intersect2
    # Testing pathological cases: Intersect one cube against another offset in
    # two directions.
    model = Sketchup.active_model
    entities = model.entities
    pts = []
    pts[0] = [0, 0, 0]
    pts[1] = [100, 0, 0]
    pts[2] = [100, 100, 0]
    pts[3] = [0, 100, 0]

    #Test instance.intersect
    definition = model.definitions.add("component")
    # Add the face to the entities in the group
    face = definition.entities.add_face pts
    status = face.pushpull -100, true
    origin = Geom::Point3d.new 0, 0, 0
    transform = Geom::Transformation.new origin
    point = Geom::Point3d.new 50, 25, 0
    t = Geom::Transformation.new point
    golden = entities.add_group

    pts1 = []
    pts1[0] = [0, 0, 0]
    pts1[1] = [0, 75, 0]
    pts1[2] = [50, 75, 0]
    pts1[3] = [50, 0, 0]

    # Add the face to the entities in the group
    face = golden.entities.add_face pts1
    status = face.pushpull -100, true

    # where does this need to go?
    golden.transform! t
    instance1 = entities.add_instance definition, transform
    instance2 = instance1.copy
    instance2.move! t
    intersection = instance1.intersect(instance2)
    assert(golden.equals?(intersection), 'instance.intersect failed')
  end
end
