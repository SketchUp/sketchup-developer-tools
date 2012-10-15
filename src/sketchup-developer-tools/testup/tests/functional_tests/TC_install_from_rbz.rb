#-----------------------------------------------------------------------------
#
# Copyright:: Copyright 2012 Trimble Navigation Ltd.
# License:: Apache License version 2.0
# Original Author:: Scott Lininger 
#
# Tests the SketchUp.install_from_archive method.
#-----------------------------------------------------------------------------

require 'sketchup.rb'
require 'test/unit'

# Test class for Sketchup.install_from_archive.
#
class TC_install_from_rbz < Test::Unit::TestCase

  def setup
    @supporting_data_dir = __FILE__.slice(0, __FILE__.rindex('.'))
    @examples_path = Sketchup.find_support_file('examples.rb', 'plugins')
    @plugins_dir = @examples_path.slice(0, @examples_path.rindex('/'))
  end

  def test_no_file_name
    assert_raise(ArgumentError) {
        success = Sketchup.install_from_archive
      }
  end

  def test_wrong_file_name
    assert_raise(Exception) {
      Sketchup.install_from_archive('foo', false)
    }

    assert_raise(Exception) {
      Sketchup.install_from_archive('c:\foo', false)
    }

    assert_raise(Exception) {
      Sketchup.install_from_archive('c:/foo', false)
    }

    assert_raise(Exception) {
      Sketchup.install_from_archive('\\foo', false)
    }

    assert_raise(Exception) {
      Sketchup.install_from_archive('http:\\foo', false)
    }
  end

  def test_basic_install
    rbz_file = @supporting_data_dir + "/test_rbz_1.rbz"
    expected_file = @plugins_dir + "/test_rbz_1.rb"

    # This file should NOT exist in the plugins directory, yet.
    assert(File.exist?(expected_file) == false)

    Sketchup.install_from_archive(rbz_file, false)

    # A new file should exist in the plugins directory, now.
    assert(File.exist?(expected_file) == true)

    # And that file should have been evaluated, setting a global variable.
    assert($test_rbz_1_times_loaded == 1)

    # Cleanup. This shouldn't fail since the file is there, right?
    File.delete(expected_file)
  end

  def test_basic_reinstall
    rbz_file = @supporting_data_dir + "/test_rbz_1.rbz"
    expected_file = @plugins_dir + "/test_rbz_1.rb"

    # This file should NOT exist in the plugins directory, yet.
    assert(File.exist?(expected_file) == false)

    Sketchup.install_from_archive(rbz_file, false)

    # A new file should exist in the plugins directory, now.
    assert(File.exist?(expected_file) == true)

    # And that file should have been evaluated, setting a global variable.
    assert($test_rbz_1_times_loaded == 1)

    # This should do nothing, leaving $test_rbz_1_times_loaded at 1.
    Sketchup.install_from_archive(rbz_file, false)
    assert($test_rbz_1_times_loaded == 1)

    # Cleanup. This shouldn't fail since the file is there, right?
    File.delete(expected_file)
  end

  def test_basic_extension_install
    rbz_file = @supporting_data_dir + "/test_rbz_2.rbz"
    expected_file_1 = @plugins_dir + "/test_rbz_2_loader.rb"
    expected_file_2 = @plugins_dir + "/test_rbz_2/test_rbz_2.rb"

    # These files should NOT exist in the plugins directory, yet.
    assert(File.exist?(expected_file_1) == false)
    assert(File.exist?(expected_file_2) == false)

    Sketchup.install_from_archive(rbz_file, false)

    # A new file should exist in the plugins directory, now.
    assert(File.exist?(expected_file_1) == true)
    assert(File.exist?(expected_file_2) == true)

    # And that file should have been evaluated and loaded,
    # setting a global variable.
    assert($test_rbz_2_times_loaded == 1)

    # Cleanup. This shouldn't fail since the file is there, right?
    File.delete(expected_file_1)
    File.delete(expected_file_2)
    Dir.delete(@plugins_dir + "/test_rbz_2")
  end

  def test_basic_exension_install_no_load
    rbz_file = @supporting_data_dir + "/test_rbz_3.rbz"
    expected_file_1 = @plugins_dir + "/test_rbz_3_loader.rb"
    expected_file_2 = @plugins_dir + "/test_rbz_3/test_rbz_3.rb"

    # These files should NOT exist in the plugins directory, yet.
    assert(File.exist?(expected_file_1) == false, 'expected file 1 exists')
    assert(File.exist?(expected_file_2) == false, 'expected file 2 exists')

    Sketchup.install_from_archive(rbz_file, false)

    # A new file should exist in the plugins directory, now.
    assert(File.exist?(expected_file_1) == true, 'file 1 did not install')
    assert(File.exist?(expected_file_2) == true, 'file 2 did not install')

    # And that file should NOT have been evaluated and loaded,
    # so this global variable should not be set.
    assert($test_rbz_3_times_loaded == nil)

    # Cleanup. This shouldn't fail since the file is there, right?
    File.delete(expected_file_1)
    File.delete(expected_file_2)
    Dir.delete(@plugins_dir + "/test_rbz_3")
  end
end
