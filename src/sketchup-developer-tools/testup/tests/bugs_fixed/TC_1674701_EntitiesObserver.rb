#!/usr/bin/ruby
#
# Copyright:: Copyright 2012 Trimble Navigation Ltd.
# License:: Apache License version 2.0
# Original Author:: Scott Lininger 
#
# Regression test for Buganizer Bug #1674701
#


require 'test/unit'

# Tests for Ruby Fixit 2009: http://b/1674701
#

# A custom observer class to test the definitions observer.
#
class MyEntObserver_1674701 < Sketchup::DefinitionsObserver

  def onContentsModified(entities)
    $tc_1674701_onContentsModifiedCount += 1
    $tc_1674701_onContentsModified_entities = entities.to_s
    puts("onContentsModified: " + entities.to_s)
  end

  def onElementAdded(entities, entity)
    $tc_1674701_onElementAdded_entities = entities.to_s
    $tc_1674701_onElementAdded_entity = entity.to_s
    puts("onElementAdded: " + entity.to_s)
  end

  def onElementRemoved(entities, entity_id)
    $tc_1674701_onElementRemoved_entities = entities.to_s
    $tc_1674701_onElementRemoved_entity_id = entity_id.to_s
    puts("onElementRemoved: " + entity_id.to_s)
  end

  def onEraseEntities(entities)
    $tc_1674701_onEraseEntities_entities = entities.to_s
    puts("onEraseEntities: " + entity.to_s)
  end
end

# The main test class.
#
class TC_1674701_EntitiesObserver < Test::Unit::TestCase

  def test_ElementAddAndRemove
    m = Sketchup.active_model
    ents = m.entities
    # Start fresh...
    ents.clear!

    $tc_1674701_onElementAdded_entities = 'none'
    $tc_1674701_onElementAdded_entity = 'none'
    $tc_1674701_onElementRemoved_entities = 'none'
    $tc_1674701_onElementRemoved_entity = 'none'

    # Add an observer to the entities collection of the model.
    obs = m.entities.add_observer(MyEntObserver_1674701.new)

    # Add a line and remove it and make sure we get expected callbacks.
    entities = m.entities
    entity = entities.add_line([0,0,0], [9,9,9])
    assert_equal($tc_1674701_onElementAdded_entity,
        entity.to_s)
    assert_equal($tc_1674701_onElementAdded_entities,
        entities.to_s)

    entity_id = entity.entityID

    # This should now fire onElementRemoved
    entity.erase!

    assert_equal($tc_1674701_onElementRemoved_entity_id,
        entity_id.to_s)
    assert_equal($tc_1674701_onElementRemoved_entities,
        entities.to_s)

    m.entities.remove_observer(obs)
  end

end
