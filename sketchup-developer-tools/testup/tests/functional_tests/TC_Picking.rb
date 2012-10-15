#!/usr/bin/ruby
#
# Copyright:: Copyright 2012 Trimble Navigation Ltd.
# License:: Apache License version 2.0
# Original Author:: Matt Lowrie 
#
# Functional picking tests for SketchUp.
#
# $Id: //depot/eng/doc/rubyguide.html#35 $

require 'test/unit'
require 'platformhelper' unless RUBY_PLATFORM.include? 'darwin'

# In case we are on Mac we do not want to define a class relying
# on the Windows only PLatformHelper, we instead define a class
# that has a single method displaying an error clearly stating that
# we can only run these tests on Windows.
if RUBY_PLATFORM.include? 'darwin'
  class TC_Picking < Test::Unit::TestCase

    def test_mac
      raise('Wrong Platform - this test can only run on Windows')
    end

  end

else

  class TC_Picking < Test::Unit::TestCase

    # Override the TestCase class initializer.
    #
    # Resizing the window is expensive, so we only want to do it once in the
    # class initializer.
    #
    def initialize arg
      super arg
      # Platform helper to manipulate the SketchUp application window
      @platform_helper = PlatformHelper.new
      # To accurately test pick rays, we need to have a known view area size
      @test_resize_dimension = 500
      su_window = @platform_helper.get_window_handle('SketchUp', 'SketchUp')
      @platform_helper.resize_window(su_window,
                                     @test_resize_dimension,
                                     @test_resize_dimension,
                                     'AfxFrameOrView')
    end


    def setup
      # Check that the view has not resized between each test
      viewport_width = Sketchup.active_model.active_view.vpwidth
      viewport_height = Sketchup.active_model.active_view.vpheight
      assert_equal(@test_resize_dimension, viewport_width,
                   'The SketchUp window did not resize correctly.' +
                   'Aborting test.')
      assert_equal(@test_resize_dimension, viewport_height,
                   'The SketchUp window did not resize correctly.' +
                   'Aborting test.')

      # Clean up the model
      m = Sketchup.active_model
      @v = m.active_view
      @s = m.selection
      @s.clear
      @ents = m.entities
      @ents.clear!

      # Draw an array of faces as our test entities... 10 unit faces with 2 units
      # spacing between
      (-29..19).step(12) do |x|
        (-29..19).step(12) do |y|
          pts = [x, y, 0], [x + 10, y, 0], [x + 10, y + 10, 0], [x, y + 10, 0]
          @ents.add_face(pts)
        end
      end
     end

    def test_perspective_center_pick_at_10_units
      # A camera at 100 units
      test_cam = Sketchup::Camera.new([10, 10, 10], [0, 0, 0], [0, 0, 1])
      test_cam.perspective = true
      @v.camera = test_cam
      @v.refresh

      mid = @test_resize_dimension / 2
      test_pick_helper = @v.pick_helper
      test_pick_helper.do_pick(mid, mid)
      # Show the selection for fun
      @s.add(test_pick_helper.all_picked)
      # Picking is non-deterministic. Sometimes this pick catches a Drawing
      # Element entity, so the length can be 1 or 2.
      assert_equal(2, test_pick_helper.count,
                   'Camera at 10-units did not pick expected number of entities')
    end

    def test_perspective_center_pick_at_100_units
      # A camera at 100 units
      test_cam = Sketchup::Camera.new([100, 100, 100], [0, 0, 0], [0, 0, 1])
      test_cam.perspective = true
      @v.camera = test_cam
      @v.refresh

      mid = @test_resize_dimension / 2
      test_pick_helper = @v.pick_helper
      test_pick_helper.do_pick(mid, mid)
      # Show the selection for fun
      @s.clear
      @s.add(test_pick_helper.all_picked)
      assert_equal(2, test_pick_helper.count,
                   'Camera at 100-units did not pick expected number of entities')
    end

    def test_perspective_center_pick_at_1000_units
      # A camera at 1000 units
      test_cam = Sketchup::Camera.new([1000, 1000, 1000], [0, 0, 0], [0, 0, 1])
      test_cam.perspective = true
      @v.camera = test_cam
      @v.refresh

      mid = @test_resize_dimension / 2
      test_pick_helper = @v.pick_helper
      test_pick_helper.do_pick(mid, mid)
      # Show the selection for fun
      @s.clear
      @s.add(test_pick_helper.all_picked)
      assert_equal(6, test_pick_helper.count,
                   "Camera at 1000-units didn't pick expected number of entities")
    end

    def test_perspective_center_pick_at_5000_units
      # A camera at 5000 units
      test_cam = Sketchup::Camera.new([5000, 5000, 5000], [0, 0, 0], [0, 0, 1])
      test_cam.perspective = true
      @v.camera = test_cam
      @v.refresh

      mid = @test_resize_dimension / 2
      test_pick_helper = @v.pick_helper
      test_pick_helper.do_pick(mid, mid)
      # Show the selection for fun
      @s.clear
      @s.add(test_pick_helper.all_picked)
      assert_equal(48, test_pick_helper.count,
                   "Camera at 5000-units didn't pick expected number of entities")
    end

    def test_orthographic_center_pick_at_10_units
      # A camera at 10 units
      test_cam = Sketchup::Camera.new([10, 10, 10], [0, 0, 0], [0, 0, 1])
      test_cam.perspective = false
      @v.camera = test_cam
      @v.refresh

      mid = @test_resize_dimension / 2
      test_pick_helper = @v.pick_helper
      test_pick_helper.do_pick(mid, mid)
      # Show the selection for fun
      @s.add(test_pick_helper.all_picked)
      # Picking is non-deterministic. Sometimes this pick catches a Drawing
      # Element entity, so the length can be 1 or 2.
      assert_equal(2, test_pick_helper.count,
                   'Camera at 10-units did not pick expected number of entities')
    end

    def test_orthographic_center_pick_at_100_units
      # A camera at 100 units
      test_cam = Sketchup::Camera.new([100, 100, 100], [0, 0, 0], [0, 0, 1])
      test_cam.perspective = false
      @v.camera = test_cam
      @v.refresh

      mid = @test_resize_dimension / 2
      test_pick_helper = @v.pick_helper
      test_pick_helper.do_pick(mid, mid)
      # Show the selection for fun
      @s.clear
      @s.add(test_pick_helper.all_picked)
      assert_equal(2, test_pick_helper.count,
                   'Camera at 100-units did not pick expected number of entities')
    end

    def test_orthographic_center_pick_at_1000_units
      # A camera at 1000 units
      test_cam = Sketchup::Camera.new([1000, 1000, 1000], [0, 0, 0], [0, 0, 1])
      test_cam.perspective = false
      @v.camera = test_cam
      @v.refresh

      mid = @test_resize_dimension / 2
      test_pick_helper = @v.pick_helper
      test_pick_helper.do_pick(mid, mid)
      # Show the selection for fun
      @s.clear
      @s.add(test_pick_helper.all_picked)
      assert_equal(6, test_pick_helper.count,
                   "Camera at 1000-units didn't pick expected number of entities")
    end

    def test_orthographic_center_pick_at_5000_units
      # Now a camera at 1000 units
      test_cam = Sketchup::Camera.new([5000, 5000, 5000], [0, 0, 0], [0, 0, 1])
      test_cam.perspective = false
      @v.camera = test_cam
      @v.refresh

      mid = @test_resize_dimension / 2
      test_pick_helper = @v.pick_helper
      test_pick_helper.do_pick(mid, mid)
      # Show the selection for fun
      @s.clear
      @s.add(test_pick_helper.all_picked)
      assert_equal(48, test_pick_helper.count,
                   "Camera at 5000-units didn't pick expected number of entities")
    end
  end
end
