#!/usr/bin/ruby
#
# Copyright:: Copyright 2012 Trimble Navigation Ltd.
# License:: Apache License version 2.0
# Original Author:: Matt Lowrie 
# Author: Simone Nicolo 
#
# Regression test for Buganizer Bug #2225435
#


require 'test/unit'
require 'timeout'


# MaterialsObserver class to test
#
#   Each callback method sends its name back to the unit test class for
#   validation.
#
class MyTestMaterialsObserver < Sketchup::MaterialsObserver
  def onMaterialUndoRedo materials, material
    TC_2225435.add_callback_name 'onMaterialUndoRedo'
  end
end


# The main test class.
#
class TC_2225435 < Test::Unit::TestCase

  def setup
    @@callback_names = nil
  end

  def teardown
    @@callback_names = nil
  end

  def self.add_callback_name name
    if @@callback_names.nil?
      @@callback_names = []
    end
    @@callback_names << name
  end

  def test_2225435_undoing_add
    m = Sketchup.active_model
    ents = m.entities
    # Start fresh...
    ents.clear!
    m.materials.purge_unused

    # Add some material events
    m.materials.add 'red'
    test_observer = MyTestMaterialsObserver.new
    m.materials.add_observer test_observer
    # Now undo the event
    Sketchup.undo
    begin
      timeout 1.0 do
        while @@callback_names.nil? do
          sleep 0.2
        end
      end
    assert(@@callback_names.include?('onMaterialUndoRedo'),
           'MaterialsObserver.onMaterialUndoRedo not called after undoing ' +
           'a material event.')
    rescue TimeoutError
        # TimeoutError means the callback never happened, so flunk it
        flunk 'MaterialsObserver.onMaterialUndoRedo callback never called.'
    ensure
      # Clean up for next test
      m.materials.remove_observer test_observer
      test_observer = nil
      m.materials.current = nil
      m.materials.purge_unused
      @@callback_data = nil
    end
  end

  def test_2225435_undoing_change
    m = Sketchup.active_model
    ents = m.entities
    # Start fresh...
    ents.clear!
    m.materials.purge_unused

    # Add some material events
    m.materials.add 'green'
    m.materials[0].color = Sketchup::Color.new 'yellow'
    test_observer = MyTestMaterialsObserver.new
    m.materials.add_observer test_observer
    # Now undo the event
    Sketchup.undo
    begin
      timeout 1.0 do
        while @@callback_names.nil? do
          sleep 0.2
        end
      end
    assert(@@callback_names.include?('onMaterialUndoRedo'),
           'MaterialsObserver.onMaterialUndoRedo not called after undoing ' +
           'a material event.')
    rescue TimeoutError
        # TimeoutError means the callback never happened, so flunk it
        flunk 'MaterialsObserver.onMaterialUndoRedo callback never called.'
    ensure
      # Clean up for next test
      m.materials.remove_observer test_observer
      test_observer = nil
      m.materials.current = nil
      m.materials.purge_unused
      @@callback_data = nil
    end
  end

  def test_2225435_undoing_set_current
    m = Sketchup.active_model
    ents = m.entities
    # Start fresh...
    ents.clear!
    m.materials.purge_unused

    # Add some material events
    m.materials.add 'green'
    m.materials.current = 'green'
    test_observer = MyTestMaterialsObserver.new
    m.materials.add_observer test_observer
    # Now undo the event
    Sketchup.undo
    begin
      timeout 1.0 do
        while @@callback_names.nil? do
          sleep 0.2
        end
      end
    assert(@@callback_names.include?('onMaterialUndoRedo'),
           'MaterialsObserver.onMaterialUndoRedo not called after undoing ' +
           'a material event.')
    rescue TimeoutError
        # TimeoutError means the callback never happened, so flunk it
        flunk 'MaterialsObserver.onMaterialUndoRedo callback never called.'
    ensure
      # Clean up for next test
      m.materials.remove_observer test_observer
      test_observer = nil
      m.materials.current = nil
      m.materials.purge_unused
      @@callback_data = nil
    end
  end
end
