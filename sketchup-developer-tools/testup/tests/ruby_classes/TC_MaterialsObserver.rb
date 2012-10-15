#!/usr/bin/ruby
#
# Copyright:: Copyright 2012 Trimble Navigation Ltd.
# License:: Apache License version 2.0
# Original Author:: Matt Lowrie 
#
# Test suite for the MaterialsObserver class.
#
# $Id: //depot/eng/doc/rubyguide.html#35 $

require 'test/unit'
require 'timeout'


# MaterialsObserver class to test
#
#   Each callback method sends its data back to the unit test class for
#   validation.
#
class MyTestMaterialsObserver < Sketchup::MaterialsObserver
  def onMaterialAdd materials, material
    _SendCallbackMessage 'onMaterialAdd', materials, material
  end

  def onMaterialChange materials, material
    _SendCallbackMessage 'onMaterialChange', materials, material
  end

  def onMaterialUndoRedo materials, material
    _SendCallbackMessage 'onMaterialUndoRedo', materials, material
  end

  def onMaterialRefChange materials, material
    _SendCallbackMessage 'onMaterialRefChange', materials, material
  end

  def onMaterialRemove materials, material
    _SendCallbackMessage 'onMaterialRemove', materials, material
  end

  def onMaterialRemoveAll materials
    _SendCallbackMessage 'onMaterialRemoveAll', materials, nil
  end

  def onMaterialSetCurrent materials, material
    _SendCallbackMessage 'onMaterialSetCurrent', materials, material
  end

  def _SendCallbackMessage callback_name, materials, material
    callback_data = _FormatCallbackData materials, material
    TC_MaterialsObserver.set_callback_data callback_name, callback_data
  end

  def _FormatCallbackData materials, material
    d = {'materials' => {}, 'material' => {}}
    # Materials class data
    if not materials.nil? and materials.is_a? Sketchup::Materials
      d['materials']['is_type_materials'] = true
      d['materials']['count'] = materials.count
      d['materials']['length'] = materials.length
    else
      d['materials']['is_type_materials'] = false
    end
    # Material class data
    if not material.nil? and material.is_a? Sketchup::Material
      d['material']['is_type_material'] = true
      d['material']['alpha'] = material.alpha
      d['material']['color'] = material.color
      d['material']['display_name'] = material.display_name
      d['material']['materialType'] = material.materialType
      d['material']['name'] = material.name
      d['material']['texture'] = material.texture
      d['material']['use_alpha'] = material.use_alpha?
    else
      d['material']['is_type_material'] = false
    end
    return d
  end
end


# The main test class.
#
class TC_MaterialsObserver < Test::Unit::TestCase

  def setup
    @@callback_data = nil

    # Let's load a simple model.
    test_model = 'blank.skp'
    local_path = __FILE__.slice(0, __FILE__.rindex('.'))
    test_model_path = File.join(local_path, test_model)
    Sketchup.open_file test_model_path
  end

  def teardown
    @@callback_data = nil
  end

  def self.set_callback_data method, data
    # I believe these callbacks are synchronous for a single observer class, so
    # we should not have to Mutex.synchronize, which we cannot do anyway since
    # Mutex is not compiled into the SketchUp Ruby engine
    if @@callback_data.nil?
      @@callback_data = {}
    end
    @@callback_data[method] = data
  end

  def test_on_material_add
    m = Sketchup.active_model
    ents = m.entities
    # Start fresh...
    ents.clear!
    m.definitions.purge_unused
    m.layers.purge_unused
    m.styles.purge_unused
    m.materials.purge_unused

    test_observer = MyTestMaterialsObserver.new
    m.materials.add_observer test_observer
    m.materials.add 'Fred'
    begin
      # This allows us to timeout and fail if the callback never gets called
      timeout 1.0 do
        while @@callback_data.nil? do
          sleep 0.2
        end
      end
      # Got the callback data, now we can test
      # First make sure we are only getting the expected callbacks
      assert(@@callback_data.has_key?('onMaterialAdd'),
             'onMaterialAdd not called after adding a new material.')
      assert_equal(false, @@callback_data.has_key?('onMaterialChange'),
                   'onMaterialChange callback unexpectedly called after ' +
                   'adding a new material.')
      assert_equal(false, @@callback_data.has_key?('onMaterialUndoRedo'),
                   'onMaterialUndoRedo callback unexpectedly called after ' +
                   'adding a new material.')
      assert_equal(false, @@callback_data.has_key?('onMaterialRefChange'),
                   'onMaterialRefChange callback unexpectedly called after ' +
                   'adding a new material.')
      assert_equal(false, @@callback_data.has_key?('onMaterialRemove'),
                   'onMaterialRemove callback unexpectedly called after ' +
                   'adding a new material.')
      assert_equal(false, @@callback_data.has_key?('onMaterialRemoveAll'),
                   'onMaterialRemoveAll callback unexpectedly called after ' +
                   'adding a new material.')
      assert_equal(false, @@callback_data.has_key?('onMaterialSetCurrent'),
                   'onMaterialSetCurrent callback unexpectedly called after ' +
                   'adding a new material.')
      # Now check the callback data
      callback_data = @@callback_data['onMaterialAdd']
      assert(callback_data['materials']['is_type_materials'],
             'MaterialsObserver.onMaterialAdd callback does not return a ' +
             'Sketchup::Materials object.')
      assert(callback_data['material']['is_type_material'],
             'MaterialsObserver.onMaterialAdd callback does not return a ' +
             'Sketchup::Material object.')
      assert_equal(1, callback_data['materials']['length'],
                   'MaterialsObserver.onMaterialAdd callback returns the ' +
                   'wrong materials collection length.')
      assert_equal(1.0, callback_data['material']['alpha'],
                   'MaterialsObserver.onMaterialAdd callback returns the ' +
                   'wrong default alpha value for a new material.')
      assert(callback_data['material']['color'].is_a?(Sketchup::Color),
             'MaterialsObserver.onMaterialAdd callback returns the wrong ' +
             'material color type.')
      assert_equal('Fred', callback_data['material']['display_name'],
                   'MaterialsObserver.onMaterialAdd callback returns the ' +
                   'wrong value for the material display name.')
      assert_equal(0, callback_data['material']['materialType'],
                   'MaterialsObserver.onMateialAdd callback returns the ' +
                   'wrong value for the default material type.')
      assert_equal('Fred', callback_data['material']['name'],
                   'MaterialsObserver.onMaterialAdd callback returns the ' +
                   'wrong value for the material name.')
      assert_nil(callback_data['material']['texture'],
                 'MaterialsObserver.onMaterialAdd callback returns the wrong ' +
                 'value for the default material texture.')
      assert_equal(false, callback_data['material']['use_alpha'],
                   'MaterialsObserver.onMaterialAdd callback returns the ' +
                   'wrong value for the default material use_alpha? attribute.')
    rescue TimeoutError
        # TimeoutError means the callback never happened, so flunk it
        flunk 'MaterialsObserver.onMaterialAdd callback was never called.'
    ensure
      # Clean up for next test
      m.materials.remove_observer test_observer
      test_observer = nil
      m.materials.current = nil
      m.materials.purge_unused
      @@callback_data = nil
    end
  end

  def test_on_material_change
    m = Sketchup.active_model
    ents = m.entities
    # Start fresh...
    ents.clear!
    m.definitions.purge_unused
    m.layers.purge_unused
    m.styles.purge_unused
    m.materials.purge_unused

    m.materials.add 'Barney'
    test_observer = MyTestMaterialsObserver.new
    m.materials.add_observer test_observer
    m.materials[0].color = Sketchup::Color.new 'black'
    begin
      # This allows us to timeout and fail if the callback never gets called
      timeout 1.0 do
        while @@callback_data.nil? do
          sleep 0.2
        end
      end
      # Got the callback data, now we can test
      # First make sure we are only getting the expected callbacks
      assert(@@callback_data.has_key?('onMaterialChange'),
             'onMaterialChange not called after changing a material.')
      assert_equal(false, @@callback_data.has_key?('onMaterialAdd'),
                   'onMaterialAdd callback unexpectedly called after ' +
                   'changing a material.')
      assert_equal(false, @@callback_data.has_key?('onMaterialUndoRedo'),
                   'onMaterialUndoRedo callback unexpectedly called after ' +
                   'changing a material.')
      assert_equal(false, @@callback_data.has_key?('onMaterialRefChange'),
                   'onMaterialRefChange callback unexpectedly called after ' +
                   'changing a material.')
      assert_equal(false, @@callback_data.has_key?('onMaterialRemove'),
                   'onMaterialRemove callback unexpectedly called after ' +
                   'changing a material.')
      assert_equal(false, @@callback_data.has_key?('onMaterialRemoveAll'),
                   'onMaterialRemoveAll callback unexpectedly called after ' +
                   'changing a material.')
      assert_equal(false, @@callback_data.has_key?('onMaterialSetCurrent'),
                   'onMaterialSetCurrent callback unexpectedly called after ' +
                   'changing a material.')
      # Now check the callback data
      callback_data = @@callback_data['onMaterialChange']
      assert(callback_data['materials']['is_type_materials'],
             'MaterialsObserver.onMaterialChange callback does not return a ' +
             'Sketchup::Materials object.')
      assert(callback_data['material']['is_type_material'],
             'MaterialsObserver.onMaterialChange callback does not return a ' +
             'Sketchup::Material object.')
      # If either of the 2 preceeding assets fail, it will fail the entire test
      # so we do not have to verify before checking each class attribute value
      assert_equal(1, callback_data['materials']['count'],
                   'MaterialsObserver.onMaterialChange callback returns the ' +
                   'wrong materials collection count.')
      assert_equal(1, callback_data['materials']['length'],
                   'MaterialsObserver.onMaterialChange callback returns the ' +
                   'wrong materials collection length.')
      assert_equal(1.0, callback_data['material']['alpha'],
                   'MaterialsObserver.onMaterialChange callback returns the ' +
                   'wrong default alpha value for a new material.')
      assert(callback_data['material']['color'].is_a?(Sketchup::Color),
             'MaterialsObserver.onMaterialChange callback returns the wrong ' +
             'material color type.')
      assert_equal('Barney', callback_data['material']['display_name'],
                   'MaterialsObserver.onMaterialChange callback returns the ' +
                   'wrong value for the material display name.')
      assert_equal(0, callback_data['material']['materialType'],
                   'MaterialsObserver.onMateialAdd callback returns the ' +
                   'wrong value for the default material type.')
      assert_equal('Barney', callback_data['material']['name'],
                   'MaterialsObserver.onMaterialChange callback returns the ' +
                   'wrong value for the material name.')
      assert_nil(callback_data['material']['texture'],
                 'MaterialsObserver.onMaterialChange callback returns the ' +
                 'wrong value for the default material texture.')
      assert_equal(false, callback_data['material']['use_alpha'],
                   'MaterialsObserver.onMaterialChange callback returns the ' +
                   'wrong value for the default material use_alpha? attribute.')
    rescue TimeoutError
        # TimeoutError means the callback never happened, so flunk it
        flunk 'MaterialsObserver.onMaterialChange callback was never called.'
    ensure
      # Clean up for next test
      m.materials.remove_observer test_observer
      test_observer = nil
      m.materials.current = nil
      m.materials.purge_unused
      @@callback_data = nil
    end
  end

  def test_on_material_refchange
    m = Sketchup.active_model
    ents = m.entities
    # Start fresh...
    ents.clear!
    m.definitions.purge_unused
    m.layers.purge_unused
    m.styles.purge_unused
    m.materials.purge_unused

    f = ents.add_face [[0, 0, 0], [0, 10, 0], [10, 10, 0], [10, 0, 0]]
    m.materials.add 'Betty'
    test_observer = MyTestMaterialsObserver.new
    m.materials.add_observer test_observer
    f.material = m.materials[0]
    begin
      # This allows us to timeout and fail if the callback never gets called
      timeout 1.0 do
        while @@callback_data.nil? do
          sleep 0.2
        end
      end
      # Got the callback data, now we can test
      # First make sure we are only getting the expected callbacks
      assert(@@callback_data.has_key?('onMaterialRefChange'),
             'onMaterialRefChange not called after changing a material ' +
             'reference.')
      assert_equal(false, @@callback_data.has_key?('onMaterialAdd'),
                   'onMaterialAdd callback unexpectedly called after ' +
                   'changing a material reference.')
      assert_equal(false, @@callback_data.has_key?('onMaterialChange'),
                   'onMaterialChange callback unexpectedly called after ' +
                   'changing a material reference.')
      assert_equal(false, @@callback_data.has_key?('onMaterialUndoRedo'),
                   'onMaterialUndoRedo callback unexpectedly called after ' +
                   'changing a material reference.')
      assert_equal(false, @@callback_data.has_key?('onMaterialRemove'),
                   'onMaterialRemove callback unexpectedly called after ' +
                   'changing a material reference.')
      assert_equal(false, @@callback_data.has_key?('onMaterialRemoveAll'),
                   'onMaterialRemoveAll callback unexpectedly called after ' +
                   'changing a material reference.')
      assert_equal(false, @@callback_data.has_key?('onMaterialSetCurrent'),
                   'onMaterialSetCurrent callback unexpectedly called after ' +
                   'changing a material reference.')
      # Now check the callback data
      callback_data = @@callback_data['onMaterialRefChange']
      assert(callback_data['materials']['is_type_materials'],
             'MaterialsObserver.onMaterialRefChange callback does not return ' +
             'a Sketchup::Materials object.')
      assert(callback_data['material']['is_type_material'],
             'MaterialsObserver.onMaterialRefChange callback does not return ' +
             'a Sketchup::Material object.')
      # If either of the 2 preceeding assets fail, it will fail the entire test
      # so we do not have to verify before checking each class attribute value
      assert_equal(1, callback_data['materials']['count'],
                   'MaterialsObserver.onMaterialRefChange callback returns ' +
                   'the wrong materials collection count.')
      assert_equal(1, callback_data['materials']['length'],
                   'MaterialsObserver.onMaterialRefChange callback returns ' +
                   'the wrong materials collection length.')
      assert_equal(1.0, callback_data['material']['alpha'],
                   'MaterialsObserver.onMaterialRefChange callback returns ' +
                   'the wrong default alpha value for a new material.')
      assert(callback_data['material']['color'].is_a?(Sketchup::Color),
             'MaterialsObserver.onMaterialRefChange callback returns the ' +
             'wrong material color type.')
      assert_equal('Betty', callback_data['material']['display_name'],
                   'MaterialsObserver.onMaterialRefChange callback returns ' +
                   'the wrong value for the material display name.')
      assert_equal(0, callback_data['material']['materialType'],
                   'MaterialsObserver.onMateialAdd callback returns the ' +
                   'wrong value for the default material type.')
      assert_equal('Betty', callback_data['material']['name'],
                   'MaterialsObserver.onMaterialRefChange callback returns ' +
                   'the wrong value for the material name.')
      assert_nil(callback_data['material']['texture'],
                 'MaterialsObserver.onMaterialRefChange callback returns the ' +
                 'wrong value for the default material texture.')
      assert_equal(false, callback_data['material']['use_alpha'],
                   'MaterialsObserver.onMaterialRefChange callback returns ' +
                   'the wrong value for the default material use_alpha? ' +
                   'attribute.')
    rescue TimeoutError
        # TimeoutError means the callback never happened, so flunk it
        flunk 'MaterialsObserver.onMaterialRefChange callback was never called.'
    ensure
      # Clean up for next test
      m.materials.remove_observer test_observer
      test_observer = nil
      m.materials.current = nil
      m.materials.purge_unused
      @@callback_data = nil
    end
  end

  def test_on_material_remove
    m = Sketchup.active_model
    ents = m.entities
    # Start fresh...
    ents.clear!
    m.definitions.purge_unused
    m.layers.purge_unused
    m.styles.purge_unused
    m.materials.purge_unused

    m.materials.add 'Wilma'
    test_observer = MyTestMaterialsObserver.new
    m.materials.add_observer test_observer
    m.materials.purge_unused
    begin
      # This allows us to timeout and fail if the callback never gets called
      timeout 1.0 do
        while @@callback_data.nil? do
          sleep 0.2
        end
      end
      # Got the callback data, now we can test
      # First make sure we are only getting the expected callbacks
      assert(@@callback_data.has_key?('onMaterialRemove'),
             'onMaterialRemove not called after removing a material.')
      assert_equal(false, @@callback_data.has_key?('onMaterialAdd'),
                   'onMaterialAdd callback unexpectedly called after ' +
                   'removing a material.')
      assert_equal(false, @@callback_data.has_key?('onMaterialChange'),
                   'onMaterialChange callback unexpectedly called after ' +
                   'removing a material.')
      assert_equal(false, @@callback_data.has_key?('onMaterialUndoRedo'),
                   'onMaterialUndoRedo callback unexpectedly called after ' +
                   'removing a material.')
      assert_equal(false, @@callback_data.has_key?('onMaterialRefChange'),
                   'onMaterialRefChange callback unexpectedly called after ' +
                   'removing a material.')
      assert_equal(false, @@callback_data.has_key?('onMaterialRemoveAll'),
                   'onMaterialRemoveAll callback unexpectedly called after ' +
                   'removing a material.')
      assert_equal(false, @@callback_data.has_key?('onMaterialSetCurrent'),
                   'onMaterialSetCurrent callback unexpectedly called after ' +
                   'removing a material.')
      # Now check the callback data
      callback_data = @@callback_data['onMaterialRemove']
      assert(callback_data['materials']['is_type_materials'],
             'MaterialsObserver.onMaterialRemove callback does not return a ' +
             'Sketchup::Materials object.')
      assert(callback_data['material']['is_type_material'],
             'MaterialsObserver.onMaterialRemove callback does not return a ' +
             'Sketchup::Material object.')
      # If either of the 2 preceeding assets fail, it will fail the entire test
      # so we do not have to verify before checking each class attribute value
      assert_equal(0, callback_data['materials']['count'],
                   'MaterialsObserver.onMaterialRemove callback returns the ' +
                   'wrong materials collection count.')
      assert_equal(0, callback_data['materials']['length'],
                   'MaterialsObserver.onMaterialRemove callback returns the ' +
                   'wrong materials collection length.')
      assert_equal(1.0, callback_data['material']['alpha'],
                   'MaterialsObserver.onMaterialRemove callback returns the ' +
                   'wrong default alpha value for a new material.')
      assert(callback_data['material']['color'].is_a?(Sketchup::Color),
             'MaterialsObserver.onMaterialRemove callback returns the wrong ' +
             'material color type.')
      assert_equal('Wilma', callback_data['material']['display_name'],
                   'MaterialsObserver.onMaterialRemove callback returns the ' +
                   'wrong value for the material display name.')
      assert_equal(0, callback_data['material']['materialType'],
                   'MaterialsObserver.onMateialAdd callback returns the ' +
                   'wrong value for the default material type.')
      assert_equal('Wilma', callback_data['material']['name'],
                   'MaterialsObserver.onMaterialRemove callback returns the ' +
                   'wrong value for the material name.')
      assert_nil(callback_data['material']['texture'],
                 'MaterialsObserver.onMaterialRemove callback returns the ' +
                 'wrong value for the default material texture.')
      assert_equal(false, callback_data['material']['use_alpha'],
                   'MaterialsObserver.onMaterialRemove callback returns the ' +
                   'wrong value for the default material use_alpha? attribute.')
    rescue TimeoutError
        # TimeoutError means the callback never happened, so flunk it
        flunk 'MaterialsObserver.onMaterialRemove callback was never called.'
    ensure
      # Clean up for next test
      m.materials.remove_observer test_observer
      test_observer = nil
      m.materials.current = nil
      m.materials.purge_unused
      @@callback_data = nil
    end
  end

  def test_on_material_set_current
    m = Sketchup.active_model
    ents = m.entities
    # Start fresh...
    ents.clear!
    m.definitions.purge_unused
    m.layers.purge_unused
    m.styles.purge_unused
    m.materials.purge_unused

    # Add some materials to choose from
    m.materials.add 'Pebbles'
    m.materials.add 'Bam-bam'
    test_observer = MyTestMaterialsObserver.new
    m.materials.add_observer test_observer
    m.materials.current = 'Bam-bam'
    begin
      # This allows us to timeout and fail if the callback never gets called
      timeout 1.0 do
        while @@callback_data.nil? do
          sleep 0.2
        end
      end
      # Got the callback data, now we can test
      # First make sure we are only getting the expected callbacks
      assert(@@callback_data.has_key?('onMaterialSetCurrent'),
             'onMaterialSetCurrent not called after setting the current ' +
             'material.')
      assert_equal(false, @@callback_data.has_key?('onMaterialAdd'),
                   'onMaterialAdd callback unexpectedly called after setting ' +
                   'the current material.')
      assert_equal(false, @@callback_data.has_key?('onMaterialChange'),
                   'onMaterialChange callback unexpectedly called after ' +
                   'setting the current material.')
      assert_equal(false, @@callback_data.has_key?('onMaterialUndoRedo'),
                   'onMaterialUndoRedo callback unexpectedly called after ' +
                   'setting the current material.')
      assert_equal(false, @@callback_data.has_key?('onMaterialRefChange'),
                   'onMaterialRefChange callback unexpectedly called after ' +
                   'setting the current material.')
      assert_equal(false, @@callback_data.has_key?('onMaterialRemove'),
                   'onMaterialRemove callback unexpectedly called after ' +
                   'setting the current material.')
      assert_equal(false, @@callback_data.has_key?('onMaterialRemoveAll'),
                   'onMaterialRemoveAll callback unexpectedly called after ' +
                   'setting the current material.')
      # Now check the callback data
      callback_data = @@callback_data['onMaterialSetCurrent']
      assert(callback_data['materials']['is_type_materials'],
             'MaterialsObserver.onMaterialSetCurrent callback does not ' +
             'return a Sketchup::Materials object.')
      assert(callback_data['material']['is_type_material'],
             'MaterialsObserver.onMaterialSetCurrent callback does not ' +
             'return a Sketchup::Material object.')
      # If either of the 2 preceeding assets fail, it will fail the entire test
      # so we do not have to verify before checking each class attribute value
      assert_equal(2, callback_data['materials']['count'],
                   'MaterialsObserver.onMaterialSetCurrent callback returns ' +
                   'the wrong materials collection count.')
      assert_equal(2, callback_data['materials']['length'],
                   'MaterialsObserver.onMaterialSetCurrent callback returns ' +
                   'the wrong materials collection length.')
      assert_equal(1.0, callback_data['material']['alpha'],
                   'MaterialsObserver.onMaterialSetCurrent callback returns ' +
                   'the wrong default alpha value for a new material.')
      assert(callback_data['material']['color'].is_a?(Sketchup::Color),
             'MaterialsObserver.onMaterialSetCurrent callback returns the ' +
             'wrong material color type.')
      assert_equal('Bam-bam', callback_data['material']['display_name'],
                   'MaterialsObserver.onMaterialSetCurrent callback returns ' +
                   'the wrong value for the material display name.')
      assert_equal(0, callback_data['material']['materialType'],
                   'MaterialsObserver.onMaterialSetCurrent callback returns ' +
                   'the wrong value for the default material type.')
      assert_equal('Bam-bam', callback_data['material']['name'],
                   'MaterialsObserver.onMaterialSetCurrent callback returns ' +
                   'the wrong value for the material name.')
      assert_nil(callback_data['material']['texture'],
                 'MaterialsObserver.onMaterialSetCurrent callback returns ' +
                 'the wrong value for the default material texture.')
      assert_equal(false, callback_data['material']['use_alpha'],
                   'MaterialsObserver.onMaterialSetCurrent callback returns ' +
                   'wrong value for the default material use_alpha? attribute.')
    rescue TimeoutError
        # TimeoutError means the callback never happened, so flunk it
        flunk 'MaterialsObserver.onMaterialSetCurrent callback never called.'
    ensure
      # Clean up for next test
      m.materials.remove_observer test_observer
      test_observer = nil
      m.materials.current = nil
      m.materials.purge_unused
      @@callback_data = nil
    end
  end

""" Broken until Buganizer Bug #2225435 is fixed
  def test_on_material_undo_redo_by_undoing
    m = Sketchup.active_model
    ents = m.entities
    # Start fresh...
    ents.clear!
    m.definitions.purge_unused
    m.layers.purge_unused
    m.styles.purge_unused
    m.materials.purge_unused

    # Add some materials to choose from
    m.materials.add 'Mr. Slate'
    test_observer = MyTestMaterialsObserver.new
    m.materials.add_observer test_observer
    Sketchup.undo
    begin
      # This allows us to timeout and fail if the callback never gets called
      timeout 1.0 do
        while @@callback_data.nil? do
          sleep 0.2
        end
      end
      # Got the callback data, now we can test
      # First make sure we are only getting the expected callbacks
      assert(@@callback_data.has_key?('onMaterialUndoRedo'),
             'onMaterialUndoRedo not called after undoing an add material.')
      assert_equal(false, @@callback_data.has_key?('onMaterialAdd'),
                   'onMaterialAdd callback unexpectedly called after undoing ' +
                   'an add material.')
      assert_equal(false, @@callback_data.has_key?('onMaterialChange'),
                   'onMaterialChange callback unexpectedly called after ' +
                   'undoing an add material.')
      assert_equal(false, @@callback_data.has_key?('onMaterialRefChange'),
                   'onMaterialRefChange callback unexpectedly called after ' +
                   'undoing an add material.')
      assert_equal(false, @@callback_data.has_key?('onMaterialRemove'),
                   'onMaterialRemove callback unexpectedly called after ' +
                   'undoing an add material.')
      assert_equal(false, @@callback_data.has_key?('onMaterialRemoveAll'),
                   'onMaterialRemoveAll callback unexpectedly called after ' +
                   'undoing an add material.')
      assert_equal(false, @@callback_data.has_key?('onMaterialSetCurrent'),
                   'onMaterialSetCurrent callback unexpectedly called after ' +
                   'undoing an add material.')
      # Now check the callback data
      callback_data = @@callback_data['onMaterialUndoRedo']
      assert(callback_data['materials']['is_type_materials'],
             'MaterialsObserver.onMaterialUndoRedo callback does not ' +
             'return a Sketchup::Materials object.')
      assert(callback_data['material']['is_type_material'],
             'MaterialsObserver.onMaterialUndoRedo callback does not ' +
             'return a Sketchup::Material object.')
      # If either of the 2 preceeding assets fail, it will fail the entire test
      # so we do not have to verify before checking each class attribute value
      assert_equal(1, callback_data['materials']['count'],
                   'MaterialsObserver.onMaterialUndoRedo callback returns ' +
                   'the wrong materials collection count.')
      assert_equal(1, callback_data['materials']['length'],
                   'MaterialsObserver.onMaterialUndoRedo callback returns ' +
                   'the wrong materials collection length.')
      assert_equal(1.0, callback_data['material']['alpha'],
                   'MaterialsObserver.onMaterialUndoRedo callback returns ' +
                   'the wrong default alpha value for a new material.')
      assert(callback_data['material']['color'].is_a?(Sketchup::Color),
             'MaterialsObserver.onMaterialUndoRedo callback returns the ' +
             'wrong material color type.')
      assert_equal('Mr. Slate', callback_data['material']['display_name'],
                   'MaterialsObserver.onMaterialUndoRedo callback returns ' +
                   'the wrong value for the material display name.')
      assert_equal(0, callback_data['material']['materialType'],
                   'MaterialsObserver.onMaterialUndoRedo callback returns ' +
                   'the wrong value for the default material type.')
      assert_equal('Mr. Slate', callback_data['material']['name'],
                   'MaterialsObserver.onMaterialUndoRedo callback returns ' +
                   'the wrong value for the material name.')
      assert_nil(callback_data['material']['texture'],
                 'MaterialsObserver.onMaterialUndoRedo callback returns ' +
                 'the wrong value for the default material texture.')
      assert_equal(false, callback_data['material']['use_alpha'],
                   'MaterialsObserver.onMaterialUndoRedo callback returns ' +
                   'wrong value for the default material use_alpha? attribute.')
    rescue TimeoutError
        # TimeoutError means the callback never happened, so flunk it
        flunk 'MaterialsObserver.onMaterialUndoRedo callback was never called.'
    ensure
      # Clean up for next test
      m.materials.remove_observer test_observer
      test_observer = nil
      m.materials.current = nil
      m.materials.purge_unused
      @@callback_data = nil
    end
  end
"""
end
