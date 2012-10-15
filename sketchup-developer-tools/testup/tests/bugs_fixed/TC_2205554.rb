#!/usr/bin/ruby
#
# Copyright:: Copyright 2012 Trimble Navigation Ltd.
# License:: Apache License version 2.0
# Original Author:: Matt Lowrie 
#
# Regression test for Buganizer Bug #2205554
#


require 'test/unit'

# The main test class.
#
class TC_2205554 < Test::Unit::TestCase
  def test_2205554
    # Convenience: Most tests need this.
    m = Sketchup.active_model
    ents = m.entities
    # Start fresh...
    ents.clear!

    test_instance_methods = Sketchup::MaterialsObserver.instance_methods false
    assert(test_instance_methods.include?('onMaterialAdd'),
           'MaterialsObserver does not contain an onMaterialAdd ' +
           'instance method.')
    assert(test_instance_methods.include?('onMaterialChange'),
           'MaterialsObserver does not contain an onMaterialChange ' +
           'instance method.')
    assert(test_instance_methods.include?('onMaterialUndoRedo'),
           'MaterialsObserver does not contain an onMaterialUndoRedo ' +
           'instance method.')
    assert(test_instance_methods.include?('onMaterialRefChange'),
           'MaterialsObserver does not contain an onMaterialRefChange ' +
           'instance method.')
    assert(test_instance_methods.include?('onMaterialRemove'),
           'MaterialsObserver does not contain an onMaterialRemove ' +
           'instance method.')
    #This callback was deprecated in SU8
    #assert(test_instance_methods.include?('onMaterialRemoveAll'),
    #       'MaterialsObserver does not contain an onMaterialRemoveAll ' +
    #       'instance method.')
    assert(test_instance_methods.include?('onMaterialSetCurrent'),
           'MaterialsObserver does not contain an onMaterialSetCurrent ' +
           'instance method.')
  end
end
