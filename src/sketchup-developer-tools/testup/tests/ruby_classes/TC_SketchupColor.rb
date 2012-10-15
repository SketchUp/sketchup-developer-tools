# Copyright:: Copyright 2012 Trimble Navigation Ltd.
# License:: Apache License version 2.0
# Original Author:: Matt Lowrie 
#
# Tests the SketchUp Color object.
#
require 'test/unit'

class TC_SketchupColor < Test::Unit::TestCase
  def test_color_new_no_params
    c = Sketchup::Color.new
    fail_msg = 'The color object created by Sketchup::Color.new does not ' + 
               'evaluate to the default value.'
    assert_equal('Color(  0,   0,   0, 255)', c.to_s, fail_msg)
  end

  def test_color_default_red_attr
    c = Sketchup::Color.new
    fail_msg = 'The red attribute on the default color object is not set ' +
               'to zero.'
    assert_equal(0, c.red, fail_msg)
  end

  def test_color_default_green_attr
    c = Sketchup::Color.new
    fail_msg = 'The green attribute on the default color object is not set ' +
               'to zero.'
    assert_equal(0, c.green, fail_msg)
  end

  def test_color_default_blue_attr
    c = Sketchup::Color.new
    fail_msg = 'The blue attribute on the default color object is not set ' +
               'to zero.'
    assert_equal(0, c.blue, fail_msg)
  end

  def test_color_default_alpha_attr
    c = Sketchup::Color.new
    fail_msg = 'The alpha attribute on the default color object is not set ' +
               'to 255.'
    assert_equal(255, c.alpha, fail_msg)
  end
end
