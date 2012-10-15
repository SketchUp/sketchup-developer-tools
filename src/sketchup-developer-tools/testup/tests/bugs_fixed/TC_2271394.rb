#!/usr/bin/ruby
#
# Copyright:: Copyright 2012 Trimble Navigation Ltd.
# License:: Apache License version 2.0
# Original Author:: Simone Nicolo 
#
# Regression test for Buganizer Bug #2271394.
#


require 'test/unit'

# The main test class.

class MoveTestEntitiesObserver < Sketchup::EntitiesObserver
  def onElementRemoved(entities, entity_id)
    puts "Entity ID: " + entity_id.to_s + " removed."
  end
end
    

class TC_2271394 < Test::Unit::TestCase
  def setup
    Sketchup.active_model.entities.add_observer(MoveTestEntitiesObserver.new)
  end

  def test_2271394   

    # Convenience: Most tests need this.
    m = Sketchup.active_model
    ents = m.entities
    # Start fresh...
    ents.clear!
    
    # Create the geometry you need
    pts = []
    pts[0] = [0, 0, 0]
    pts[1] = [100, 0, 0]
    pts[2] = [100, 100, 0]
    pts[3] = [0, 100, 0]

    # Add the face to the entities in the model
    assert_nothing_raised do
      Sketchup.active_model.start_operation "Create/Delete Face"
      face = ents.add_face pts
      entity1 = ents[1]        
      puts entity1.deleted?
      ents.erase_entities ents[1]
      Sketchup.active_model.commit_operation
    end
  end
end
