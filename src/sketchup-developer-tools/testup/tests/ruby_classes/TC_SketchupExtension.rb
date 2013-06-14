# Copyright:: Copyright 2012 Trimble Navigation Ltd.
# License:: Apache License version 2.0
# Original Author:: Scott Lininger 
#
# Tests the SketchUp Ruby API SketchupExtension object.
#

require 'test/unit'

# TC_SketchupExtension contains unit tests for the SketchupExtension class.
#
# API Object::       SketchupExtension
# C++ File::         rextension.cpp
# Ruby File::        extensions.rb
# Version::          SketchUp 6.0
#
# The SketchupExtension class is somewhat unique in the Ruby API. Instead of
# being a compiled-code class that is exposed to Ruby, it is a Ruby class that
# gets registered with SketchUp. So any changes to the class might require
# code in both Ruby and C++.
#
class TC_SketchupExtension < Test::Unit::TestCase

  # Setup for test cases.
  #
  def setup
    # Let's create a fake extension that autoloads on startup.
    if $testup_dc_extension_autoload == nil
      local_path = __FILE__.slice(0, __FILE__.rindex('.'))
      test_path = local_path + '//testup_name_autoload.rb'

      $testup_dc_extension_autoload = SketchupExtension.new(
          'testup_name_autoload', test_path)
      $testup_dc_extension_autoload.version = 'testup_version_autoload'
      $testup_dc_extension_autoload.description = 'testup_description_autoload'
      $testup_dc_extension_autoload.creator = 'testup_creator_autoload'
      $testup_dc_extension_autoload.copyright = 'testup_copyright_autoload'
      Sketchup.register_extension $testup_dc_extension_autoload, true

      # Let's create a fake extension that does not autoload.
      test_path = local_path + '//testup_name_noload.rb'
      $testup_dc_extension_noload = SketchupExtension.new(
          'testup_name_noload', test_path)
      $testup_dc_extension_noload.version = 'testup_version_noload'
      $testup_dc_extension_noload.description = 'testup_description_noload'
      $testup_dc_extension_noload.creator = 'testup_creator_noload'
      $testup_dc_extension_noload.copyright = 'testup_copyright_noload'
      Sketchup.register_extension $testup_dc_extension_noload, false
      su_examples = Sketchup.find_support_file('Plugins') + '/su_examples'
      $test_su_examples_absent = !(File.directory? su_examples)

    end
  end

  def teardown
    $testup_dc_extension_autoload.name = 'testup_name_autoload';
    $testup_dc_extension_noload.name = 'testup_name_noload';
    $testup_dc_extension_autoload.description = 'testup_description_autoload';
    $testup_dc_extension_noload.description = 'testup_description_noload';
    $testup_dc_extension_autoload.version = 'testup_version_autoload';
    $testup_dc_extension_noload.version = 'testup_version_noload';
    $testup_dc_extension_autoload.copyright = 'testup_copyright_autoload';
    $testup_dc_extension_noload.copyright = 'testup_copyright_noload';
    $testup_dc_extension_autoload.creator = 'testup_creator_autoload';
    $testup_dc_extension_noload.creator = 'testup_creator_noload';
  end

  def examples_not_installed(test_name)
    return test_name + ' can only be run if Examples Extension is loaded ' +
        'from Extension Warehouse; search on Example Ruby Scripts by The ' +
        'SketchUp Team, and install'
  end

  def test_name
    assert_equal('testup_name_autoload', $testup_dc_extension_autoload.name,
                 'testup_name_autoload')
    assert_equal('testup_name_noload', $testup_dc_extension_noload.name,
                 'testup_name_noload')

    $testup_dc_extension_autoload.name = 'foo_name';
    assert_equal('foo_name', $testup_dc_extension_autoload.name,
                 'testup_name_autoload foo_name')

    $testup_dc_extension_noload.name = 'bar_name';
    assert_equal('bar_name', $testup_dc_extension_noload.name,
                 'testup_name_noload bar_name')
  end

  def test_description
    assert_equal('testup_description_autoload',
                 $testup_dc_extension_autoload.description,
                 'testup_description_autoload')
    assert_equal('testup_description_noload',
                 $testup_dc_extension_noload.description,
                 'testup_description_noload')

    $testup_dc_extension_autoload.description = 'foo_description';
    assert_equal('foo_description', $testup_dc_extension_autoload.description,
                 'testup_description_autoload foo')

    $testup_dc_extension_noload.description = 'bar_description';
    assert_equal('bar_description', $testup_dc_extension_noload.description,
                 'testup_description_noload bar')
  end

  def test_version
    assert_equal('testup_version_autoload',
                 $testup_dc_extension_autoload.version,
                 'testup_version_autoload')
    assert_equal('testup_version_noload',
                 $testup_dc_extension_noload.version,
                 'testup_version_noload')

    $testup_dc_extension_autoload.version = 'foo_version';
    assert_equal('foo_version', $testup_dc_extension_autoload.version,
                 'testup_version_autoload foo')

    $testup_dc_extension_noload.version = 'bar_version';
    assert_equal('bar_version', $testup_dc_extension_noload.version,
                 'testup_version_noload bar')
  end

  def test_copyright
    assert_equal('testup_copyright_autoload',
                 $testup_dc_extension_autoload.copyright,
                 'testup_copyright_autoload')
    assert_equal('testup_copyright_noload',
                 $testup_dc_extension_noload.copyright,
                 'testup_copyright_noload')

    $testup_dc_extension_autoload.copyright = 'foo_copyright';
    assert_equal('foo_copyright', $testup_dc_extension_autoload.copyright,
                 'testup_copyright_autoload foo')

    $testup_dc_extension_noload.copyright = 'bar_copyright';
    assert_equal('bar_copyright', $testup_dc_extension_noload.copyright,
                 'testup_copyright_noload bar')
  end

  def test_creator
    assert_equal('testup_creator_autoload',
                 $testup_dc_extension_autoload.creator,
                 'testup_creator_autoload')
    assert_equal('testup_creator_noload',
                 $testup_dc_extension_noload.creator,
                 'testup_creator_noload')

    $testup_dc_extension_autoload.creator = 'foo_creator';
    assert_equal('foo_creator', $testup_dc_extension_autoload.creator,
                 'testup_creator_autoload foo')

    $testup_dc_extension_noload.creator = 'bar_creator';
    assert_equal('bar_creator', $testup_dc_extension_noload.creator,
                 'testup_creator_noload bar')
  end

  def test_load_on_start?
    assert_equal(true,
                 $testup_dc_extension_autoload.load_on_start?,
                 'testup_load_on_start?_autoload')
    assert_equal(false,
                 $testup_dc_extension_noload.load_on_start?,
                 'testup_load_on_start?_noload')
  end

  def test_loaded?
    assert_equal(true,
                 $testup_dc_extension_autoload.loaded?,
                 'testup_loaded?_autoload')
    assert_equal(false,
                 $testup_dc_extension_noload.loaded?,
                 'testup_loaded?_noload')
  end

  def test_check
    if $test_su_examples_absent == true
      raise examples_not_installed('test_check')
      return
    end

    if $test_load_has_run == true
      raise('test_load can only be run once per SketchUp session.')
      return
    end

    # Create an extension and register it not to load on start.
    my_extension = SketchupExtension.new('testup_will_load' + Time.new.to_s,
        'su_examples/animation.rb')

    Sketchup.register_extension my_extension, false

    assert_equal(false, my_extension.loaded?,
                 'my_extension.loaded?')
    assert_equal(false, my_extension.load_on_start?,
                 'my_extension.load_on_start?')

    # Now load it manually. This should set loaded? to true and set
    # load_on_start to true.
    success = my_extension.check;

    assert_equal(true, my_extension.loaded?,
                 'my_extension.loaded? changed true')
    assert_equal(true, my_extension.load_on_start?,
                 'my_extension.load_on_start? true')

    # This test will fail if run a second time after startup, so set
    # a global flag so we can alert the TestUp user.
    $test_load_has_run = true
  end

  def test_register
    if $test_su_examples_absent == true
      raise examples_not_installed('test_register')
      return
    end

    if $test_register_has_run == true
      raise('test_register can only be run once per SketchUp session.')
      return
    end

    # Create an extension and register it not to load on start.
    # For this test we need to give it a unique name so it
    # always re-registers.
    name = 'testup_to_register' + Time.new.to_s
    reg_extension = SketchupExtension.new(name,
        'su_examples/box.rb')

    assert_equal(false, reg_extension.loaded?,
                 'reg_extension.loaded?')
    assert_equal(false, reg_extension.load_on_start?,
                 'reg_extension.load_on_start?')
    assert_equal(false, reg_extension.registered?,
                 'reg_extension.registered?')

    result = Sketchup.register_extension reg_extension, true
    assert_equal(true, result,
                 'reg_extension result after re-register')
    assert_equal(true, reg_extension.loaded?,
                 'reg_extension.loaded?')
    assert_equal(true, reg_extension.load_on_start?,
                 'reg_extension.load_on_start?')
    assert_equal(true, reg_extension.registered?,
                 'reg_extension.load_on_start?')

    # Now if I try to re-register, it should return false, but overwrite
    # the load_on_start param with the value I pass.
    result = Sketchup.register_extension reg_extension, false
    assert_equal(false, result,
                 'reg_extension result after re-register')
    assert_equal(true, reg_extension.loaded?,
                 'reg_extension.loaded? after re-register')
    assert_equal(false, reg_extension.load_on_start?,
                 'reg_extension.load_on_start? after re-register')
    assert_equal(true, reg_extension.registered?,
                 'reg_extension.load_on_start? after re-register')

    # This test will fail if run a second time after startup, so set
    # a global flag so we can alert the TestUp user.
    $test_register_has_run = true
  end

  def test_check_fail
    unloadable_extension = SketchupExtension.new('unloadable_extension',
        'file_that_does_not_exist.rb')
    result = unloadable_extension.check;
    assert_equal(false, result,
                 'unloadable_extension.check returned false')
    assert_equal(false, unloadable_extension.loaded?,
                 'unloadable_extension.loaded? false')
    assert_equal(false, unloadable_extension.load_on_start?,
                 'unloadable_extension.load_on_start? unchanged')
  end

  def test_check_success
    if $test_su_examples_absent == true
      raise examples_not_installed('test_check_success')
      return
    end

    if $test_load_success_has_run == true
      raise('test_load_success can only be run once per SketchUp session.')
      return
    end
    loadable_extension = SketchupExtension.new('loadable_extension',
        'su_examples/attributes.rb')

    result = loadable_extension.check;

    assert_equal(true, result,
                 'loadable_extension.check returned false')
    assert_equal(true, loadable_extension.loaded?,
                 'loadable_extension.loaded? false')
    assert_equal(false, loadable_extension.load_on_start?,
                 'loadable_extension.load_on_start? unchanged')

    # This test will fail if run a second time after startup, so set
    # a global flag so we can alert the TestUp user.
    $test_load_success_has_run = true
  end
end
