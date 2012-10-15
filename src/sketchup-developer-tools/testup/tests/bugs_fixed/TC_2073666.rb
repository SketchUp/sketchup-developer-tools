#!/usr/bin/ruby
#
# Copyright:: Copyright 2012 Trimble Navigation Ltd.
# License:: Apache License version 2.0
# Original Author:: Matt Lowrie 
#
# Regression test for Buganizer Bug #2073666
#


require 'test/unit'

# The main test class.
#
class TC_2073666 < Test::Unit::TestCase
  def test_2073666
    # Convenience: Most tests need this.
    m = Sketchup.active_model
    ents = m.entities
    # Start fresh...
    ents.clear!

    # Must have an entity selected, so draw a rectangle and select it
    pt1 = [0, 0, 0]
    pt2 = [0, 100, 0]
    pt3 = [100, 100, 0]
    pt4 = [100, 0, 0]
    ents.add_face pt1, pt2, pt3, pt4
    face_ent = nil
    ents.each { |e| face_ent = e if e.class == Sketchup::Face }
    m.selection.add face_ent

    # This procedure would crash
    m.start_operation "Bug 2073666"
    selection_set = m.selection
    copy_group = ents.add_group(selection_set)
    m.active_view.refresh
    copy_group.explode
    m.commit_operation
    # If we made it this far without crashing, we win!
    assert_equal(1, 1)
  end
end
