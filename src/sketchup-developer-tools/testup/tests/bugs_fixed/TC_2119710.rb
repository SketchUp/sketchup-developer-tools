#!/usr/bin/ruby
#
# Copyright:: Copyright 2012 Trimble Navigation Ltd.
# License:: Apache License version 2.0
# Original Author:: Matt Lowrie 
#
# Regression test for Buganizer Bug #2119710
#

require 'test/unit'
 
# this can only be required on PC

if not RUBY_PLATFORM.include? 'darwin'
  require 'platformhelper'
  require 'win32/apidefs'
  puts 'we are on windows'
end

class TC_2119710 < Test::Unit::TestCase

  def setup
    if RUBY_PLATFORM.include? 'darwin'
      raise('WARNING: this test case currently can run only on PC')
    end
    begin 
      # Set the SketchUp window to a specific size to set the pick aperture.
      @platform_helper = PlatformHelper.new
      @is_win = RUBY_PLATFORM =~ /mswin/
      su_handle = @platform_helper.get_window_handle('SketchUp', 'SketchUp')
      gl_window_class = @is_win ? 'AfxFrameOrView' : nil
      @platform_helper.resize_window(su_handle, 500, 500, gl_window_class)
    rescue 
      raise('WARNING: this test (TC_2119710) can only be run if the main ' + 
            'SketchUp window is NOT maximized. Please unmaximize your window ' +
            'and try again.');
    end
    
  end

  def test_2119710
    m = Sketchup.active_model
    v = m.active_view
    s = m.selection
    s.clear
    ents = m.entities
    ents.clear!

    Sketchup.send_action('selectSelectionTool:')

    # Add long, skinny face
    ents.add_face([-150, 1, 0], [150, 1, 0], [150, -1, 0], [-150, -1, 0])

    c = Sketchup::Camera.new([50, 50, 20], [0, 0, 0], [0, 0, 1])
    c.perspective = true
    v.camera = c
    v.refresh

    ph = v.pick_helper
    ph.do_pick(v.center.x, v.center.y)
    # Show the selected entities to the user
    s.add ph.all_picked

    # A DrawingElement and a Face get picked with this operation.
    assert_equal(2, ph.all_picked.length,
                 'Unexpected number of entities picked.')
    assert(ph.picked_face, 'A face should have been picked, but was not.')
    assert_nil(ph.picked_edge, 'An edge was picked, but should not have been.')
  end
end
