#!/usr/bin/ruby
#
# Copyright:: Copyright 2012 Trimble Navigation Ltd.
# License:: Apache License version 2.0
# Original Author:: Matt Lowrie 
#
# Regression test for Buganizer Bug #884118
#


require 'test/unit'
require 'timeout'


# MaterialsObserver class to test
#
#   Each callback method sends its name back to the unit test class for
#   validation.
#
class MyTestMaterialsObserver < Sketchup::MaterialsObserver
  def onMaterialRemoveAll materials
    TC_884118.add_callback_name 'onMaterialRemoveAll'
  end

  def onMaterialSetCurrent materials, material
    TC_884118.add_callback_name 'onMaterialSetCurrent'
  end
end


# The main test class.
#
class TC_884118 < Test::Unit::TestCase

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

  def test_884118
    m = Sketchup.active_model
    ents = m.entities
    # Start fresh...
    ents.clear!
    m.materials.purge_unused

    m.materials.add 'foo'
    test_observer = MyTestMaterialsObserver.new
    m.materials.add_observer test_observer
    m.materials.current = 'foo'
    begin
      timeout 1.0 do
        while @@callback_names.nil? do
          sleep 0.2
        end
      end
    assert(@@callback_names.include?('onMaterialSetCurrent'),
           'MaterialsObserver.onMaterialSetCurrent not called.')
    assert_equal(false, @@callback_names.include?('onMaterialRemoveAll'),
                 'MaterialsObserver.onMaterialRemoveAll unexpectedly called ' +
                 'after setting the current material.')
    rescue TimeoutError
        # TimeoutError means the callback never happened, so flunk it
        flunk 'MaterialsObserver callbacks never called.'
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
