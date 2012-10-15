#!/usr/bin/ruby
#
# Copyright:: Copyright 2012 Trimble Navigation Ltd.
# License:: Apache License version 2.0
# Original Author:: Simone Nicolo 
#
# Regression test for Buganizer Bug #<bug number>.
#


require 'test/unit'

# The main test class.
#
# This is what will be run automatically by TestUp. Make sure that your class
# name is exactly the same as your file name (minus the .rb extension). For bug
# regression tests, just replace _BUG_NUMBER in the file name, class name, and
# test_ method with the Buganizer bug number. For example, the test case for bug
# id 12345678 should be in a file named TC_12345678.rb, with a test class named
# TC_12345678 and a test method named test_12345678.
#
class TC_2412140 < Test::Unit::TestCase
 def test_2412140_add_method_with_no_params
    assert_nothing_raised do
      skp = Sketchup.active_model
      pgs = skp.pages
      added_page = pgs.add

      fail_msg = 'Added page does not have default name.'
      assert_equal('Scene', added_page.name.slice(0..4), fail_msg)
    end
  end

  def test_2412140_add_method_return_value
    assert_nothing_raised do
      skp = Sketchup.active_model
      pgs = skp.pages
      added_page = pgs.add

      fail_msg = 'Return value from Page.add is not a page object.'
      assert_equal('Sketchup::Page', added_page.class.to_s, fail_msg)
    end
  end

  def test_2412140_add_method_with_name_param
    assert_nothing_raised do
      skp = Sketchup.active_model
      pgs = skp.pages
      added_page = pgs.add "Test name for page"

      fail_msg = 'Added page does not have the supplied name.'
      assert_equal('Test name for page', added_page.name, fail_msg)
    end
  end

  def test_2412140_add_method_with_index_param
    assert_nothing_raised do
      skp = Sketchup.active_model
      pgs = skp.pages
      # Add some pages so we are sure we can have an index to insert into
      while pgs[2] == nil do pgs.add end
      old_p2 = pgs[2]
      insert_p2 = pgs.add "Index 2", 0x0fff, 2

      fail_msg = 'Page not inserted at specified index.'
      assert_equal(insert_p2, pgs[2], fail_msg)
      # Make sure old page at our inserted index was moved over
      fail_msg2 = 'Page located at same index where new page was added was ' +
                  'not moved up to the next index.'
      assert_equal(old_p2, pgs[3], fail_msg2)
    end
  end

  def test_2412140_add_method_with_index_param_larger_than_array_size
    assert_nothing_raised do
      skp = Sketchup.active_model
      pgs = skp.pages
      large_index = pgs.count
      large_index += 1000
      p = pgs.add "Large Index", 0x0fff, large_index

      fail_msg = 'Page added at index larger than pages array size was not ' +
                 'inserted at the end of the pages array.'
      assert_equal(p, pgs[pgs.count-1], fail_msg)
    end
  end

  def test_2412140_add_method_flags_param_value_0
    assert_nothing_raised do
      skp = Sketchup.active_model
      pgs = skp.pages
      p = pgs.add "Flag 0", 0

      fail_msg = 'Add page with flag 0 has use_camera set.'
      assert_equal(false, p.use_camera?, fail_msg)
      fail_msg = 'Add page with flag 0 has use_rendering_options set.'
      assert_equal(false, p.use_rendering_options?, fail_msg)
      fail_msg = 'Add page with flag 0 has use_style set.'
      assert_equal(false, p.use_style?, fail_msg)
      fail_msg = 'Add page with flag 0 has use_shadow_info set.'
      assert_equal(false, p.use_shadow_info?, fail_msg)
      fail_msg = 'Add page with flag 0 has use_axes set.'
      assert_equal(false, p.use_axes?, fail_msg)
      fail_msg = 'Add page with flag 0 has use_hidden set.'
      assert_equal(false, p.use_hidden?, fail_msg)
      fail_msg = 'Add page with flag 0 has use_hidden_layers set.'
      assert_equal(false, p.use_hidden_layers?, fail_msg)
      fail_msg = 'Add page with flag 0 has use_section_planes set.'
      assert_equal(false, p.use_section_planes?, fail_msg)
    end
  end

  def test_2412140_add_method_flags_param_value_1
    assert_nothing_raised do
      skp = Sketchup.active_model
      pgs = skp.pages
      p = pgs.add "Flag 1", 1

      fail_msg = 'Add page with flag 1 does not have use_camera set.'
      assert_equal(true, p.use_camera?, fail_msg)
      fail_msg = 'Add page with flag 1 has use_rendering_options set.'
      assert_equal(false, p.use_rendering_options?, fail_msg)
      fail_msg = 'Add page with flag 1 has use_style set.'
      assert_equal(false, p.use_style?, fail_msg)
      fail_msg = 'Add page with flag 1 has use_shadow_info set.'
      assert_equal(false, p.use_shadow_info?, fail_msg)
      fail_msg = 'Add page with flag 1 has use_axes set.'
      assert_equal(false, p.use_axes?, fail_msg)
      fail_msg = 'Add page with flag 1 has use_hidden set.'
      assert_equal(false, p.use_hidden?, fail_msg)
      fail_msg = 'Add page with flag 1 has use_hidden_layers set.'
      assert_equal(false, p.use_hidden_layers?, fail_msg)
      fail_msg = 'Add page with flag 1 has use_section_planes set.'
      assert_equal(false, p.use_section_planes?, fail_msg)
    end
  end

  def test_2412140_add_method_flags_param_value_2
    assert_nothing_raised do
      skp = Sketchup.active_model
      pgs = skp.pages
      p = pgs.add "Flag 2", 2

      fail_msg = 'Add page with flag 2 has use_camera set.'
      assert_equal(false, p.use_camera?, fail_msg)
      fail_msg = 'Add page with flag 2 does not have use_rendering_options set.'
      assert_equal(true, p.use_rendering_options?, fail_msg)
      fail_msg = 'Add page with flag 2 does not have use_style set.'
      assert_equal(true, p.use_style?, fail_msg)
      fail_msg = 'Add page with flag 2 has use_shadow_info set.'
      assert_equal(false, p.use_shadow_info?, fail_msg)
      fail_msg = 'Add page with flag 2 has use_axes set.'
      assert_equal(false, p.use_axes?, fail_msg)
      fail_msg = 'Add page with flag 2 has use_hidden set.'
      assert_equal(false, p.use_hidden?, fail_msg)
      fail_msg = 'Add page with flag 2 has use_hidden_layers set.'
      assert_equal(false, p.use_hidden_layers?, fail_msg)
      fail_msg = 'Add page with flag 2 has use_section_planes set.'
      assert_equal(false, p.use_section_planes?, fail_msg)
    end
  end

  def test_2412140_add_method_flags_param_value_4
    assert_nothing_raised do
      skp = Sketchup.active_model
      pgs = skp.pages
      p = pgs.add "Flag 4", 4

      fail_msg = 'Add page with flag 4 has use_camera set.'
      assert_equal(false, p.use_camera?, fail_msg)
      fail_msg = 'Add page with flag 4 has use_rendering_options set.'
      assert_equal(false, p.use_rendering_options?, fail_msg)
      fail_msg = 'Add page with flag 4 has use_style set.'
      assert_equal(false, p.use_style?, fail_msg)
      fail_msg = 'Add page with flag 4 does not have use_shadow_info set.'
      assert_equal(true, p.use_shadow_info?, fail_msg)
      fail_msg = 'Add page with flag 4 has use_axes set.'
      assert_equal(false, p.use_axes?, fail_msg)
      fail_msg = 'Add page with flag 4 has use_hidden set.'
      assert_equal(false, p.use_hidden?, fail_msg)
      fail_msg = 'Add page with flag 4 has use_hidden_layers set.'
      assert_equal(false, p.use_hidden_layers?, fail_msg)
      fail_msg = 'Add page with flag 4 has use_section_planes set.'
      assert_equal(false, p.use_section_planes?, fail_msg)
    end
  end

  def test_2412140_add_method_flags_param_value_8
    assert_nothing_raised do
      skp = Sketchup.active_model
      pgs = skp.pages
      p = pgs.add "Flag 8", 8

      fail_msg = 'Add page with flag 8 has use_camera set.'
      assert_equal(false, p.use_camera?, fail_msg)
      fail_msg = 'Add page with flag 8 has use_rendering_options set.'
      assert_equal(false, p.use_rendering_options?, fail_msg)
      fail_msg = 'Add page with flag 8 has use_style set.'
      assert_equal(false, p.use_style?, fail_msg)
      fail_msg = 'Add page with flag 8 has use_shadow_info set.'
      assert_equal(false, p.use_shadow_info?, fail_msg)
      fail_msg = 'Add page with flag 8 does not have use_axes set.'
      assert_equal(true, p.use_axes?, fail_msg)
      fail_msg = 'Add page with flag 8 has use_hidden set.'
      assert_equal(false, p.use_hidden?, fail_msg)
      fail_msg = 'Add page with flag 8 has use_hidden_layers set.'
      assert_equal(false, p.use_hidden_layers?, fail_msg)
      fail_msg = 'Add page with flag 8 has use_section_planes set.'
      assert_equal(false, p.use_section_planes?, fail_msg)
    end
  end

  def test_2412140_add_method_flags_param_value_16
    assert_nothing_raised do
      skp = Sketchup.active_model
      pgs = skp.pages
      p = pgs.add "Flag 16", 16

      fail_msg = 'Add page with flag 16 has use_camera set.'
      assert_equal(false, p.use_camera?, fail_msg)
      fail_msg = 'Add page with flag 16 has use_rendering_options set.'
      assert_equal(false, p.use_rendering_options?, fail_msg)
      fail_msg = 'Add page with flag 16 has use_style set.'
      assert_equal(false, p.use_style?, fail_msg)
      fail_msg = 'Add page with flag 16 has use_shadow_info set.'
      assert_equal(false, p.use_shadow_info?, fail_msg)
      fail_msg = 'Add page with flag 16 has use_axes set.'
      assert_equal(false, p.use_axes?, fail_msg)
      fail_msg = 'Add page with flag 16 does not have use_hidden set.'
      assert_equal(true, p.use_hidden?, fail_msg)
      fail_msg = 'Add page with flag 16 has use_hidden_layers set.'
      assert_equal(false, p.use_hidden_layers?, fail_msg)
      fail_msg = 'Add page with flag 16 has use_section_planes set.'
      assert_equal(false, p.use_section_planes?, fail_msg)
    end
  end

  def test_2412140_add_method_flags_param_value_32
    assert_nothing_raised do
      skp = Sketchup.active_model
      pgs = skp.pages
      p = pgs.add "Flag 32", 32

      fail_msg = 'Add page with flag 32 has use_camera set.'
      assert_equal(false, p.use_camera?, fail_msg)
      fail_msg = 'Add page with flag 32 has use_rendering_options set.'
      assert_equal(false, p.use_rendering_options?, fail_msg)
      fail_msg = 'Add page with flag 32 has use_style set.'
      assert_equal(false, p.use_style?, fail_msg)
      fail_msg = 'Add page with flag 32 has use_shadow_info set.'
      assert_equal(false, p.use_shadow_info?, fail_msg)
      fail_msg = 'Add page with flag 32 has use_axes set.'
      assert_equal(false, p.use_axes?, fail_msg)
      fail_msg = 'Add page with flag 32 has use_hidden set.'
      assert_equal(false, p.use_hidden?, fail_msg)
      fail_msg = 'Add page with flag 32 does not have use_hidden_layers set.'
      assert_equal(true, p.use_hidden_layers?, fail_msg)
      fail_msg = 'Add page with flag 32 has use_section_planes set.'
      assert_equal(false, p.use_section_planes?, fail_msg)
    end
  end

  def test_2412140_add_method_flags_param_value_64
    assert_nothing_raised do
      skp = Sketchup.active_model
      pgs = skp.pages
      p = pgs.add "Flag 64", 64

      fail_msg = 'Add page with flag 64 has use_camera set.'
      assert_equal(false, p.use_camera?, fail_msg)
      fail_msg = 'Add page with flag 64 has use_rendering_options set.'
      assert_equal(false, p.use_rendering_options?, fail_msg)
      fail_msg = 'Add page with flag 64 has use_style set.'
      assert_equal(false, p.use_style?, fail_msg)
      fail_msg = 'Add page with flag 64 has use_shadow_info set.'
      assert_equal(false, p.use_shadow_info?, fail_msg)
      fail_msg = 'Add page with flag 64 has use_axes set.'
      assert_equal(false, p.use_axes?, fail_msg)
      fail_msg = 'Add page with flag 64 has use_hidden set.'
      assert_equal(false, p.use_hidden?, fail_msg)
      fail_msg = 'Add page with flag 64 has use_hidden_layers set.'
      assert_equal(false, p.use_hidden_layers?, fail_msg)
      fail_msg = 'Add page with flag 64 does not have use_section_planes set.'
      assert_equal(true, p.use_section_planes?, fail_msg)
    end
  end

  def test_2412140_add_method_flags_param_value_4095
    assert_nothing_raised do
      skp = Sketchup.active_model
      pgs = skp.pages
      p = pgs.add "Flag 4095", 4095

      fail_msg = 'Add page with flag 4095 does not have use_camera set.'
      assert_equal(true, p.use_camera?, fail_msg)
      fail_msg = 'Add page with flag 4095 does not have use_rendering_options.'
      assert_equal(true, p.use_rendering_options?, fail_msg)
      fail_msg = 'Add page with flag 4095 does not have use_style set.'
      assert_equal(true, p.use_style?, fail_msg)
      fail_msg = 'Add page with flag 4095 does not have use_shadow_info set.'
      assert_equal(true, p.use_shadow_info?, fail_msg)
      fail_msg = 'Add page with flag 4095 does not have use_axes set.'
      assert_equal(true, p.use_axes?, fail_msg)
      fail_msg = 'Add page with flag 4095 does not have use_hidden set.'
      assert_equal(true, p.use_hidden?, fail_msg)
      fail_msg = 'Add page with flag 4095 does not have use_hidden_layers set.'
      assert_equal(true, p.use_hidden_layers?, fail_msg)
      fail_msg = 'Add page with flag 4095 does not have use_section_planes set.'
      assert_equal(true, p.use_section_planes?, fail_msg)
    end
  end
end

