#!/usr/bin/ruby
#
# Copyright:: Copyright 2012 Trimble Navigation Ltd.
# License:: Apache License version 2.0
# Original Author:: Matt Lowrie 
#
# Regression test for Buganizer Bug #2051448.
#


require 'test/unit'

# The main test class.
#
class TC_2051448< Test::Unit::TestCase
  def test_2051448
    Sketchup.file_new
    local_path = __FILE__.slice(0, __FILE__.rindex('.'))
    test_model = File.join(local_path, 'ProfilesAutoTurnedOn.skp')
    Sketchup.open_file test_model

    all_edges_style = nil
    wireframe_style = nil
    hidden_style = nil

    m = Sketchup.active_model
    styles = m.styles
    styles.each do |style|
      if style.name.match(/^Wireframe/)
        wireframe_style = style
      elsif style.name.match(/^Hidden/)
        hidden_style = style
      elsif style.name.match(/^All/)
        all_edges_style = style
      end
    end

    # First make sure the active style is the same one we saved with
    assert_equal(styles.active_style.name, all_edges_style.name,
                 'Current active style is not the same one the model was ' +
                 'originally saved with.')

    # Test switching to the wireframe style with profiles turned off
    styles.selected_style = wireframe_style
    render_opts = m.rendering_options
    # Display Edges setting is expected behavior based on http://b/1944381
    assert_equal(1, render_opts['EdgeDisplayMode'],
                 'Display Edges is turned off after choosing the "Wireframe" ' +
                 'style after having a shaded style first selected.')
    assert_equal(false, render_opts['DrawSilhouettes'],
                 'Profiles is turned on after choosing the "Wireframe" style.')
    assert_equal(false, render_opts['DrawDepthQue'],
                 'Depth cue is turned on after choosing the "Wireframe" style.')
    assert_equal(false, render_opts['ExtendLines'],
                 'Extension is turned on after choosing the "Wireframe" style.')
    assert_equal(false, render_opts['DrawLineEnds'],
                 'Endpoints is turned on after choosing the "Wireframe" style.')
    assert_equal(false, render_opts['JitterEdges'],
                 'Jitter is turned on after choosing the "Wireframe" style.')

    # Now test choosing the hidden line style with profiles off
    styles.selected_style = hidden_style
    # Same expected behavior as above
    assert_equal(1, render_opts['EdgeDisplayMode'],
                 'Display Edges is turned off after choosing the "Hidden ' +
                 'line" style after having a shaded style first selected.')
    assert_equal(false, render_opts['DrawSilhouettes'],
                 'Profiles is turned on after choosing "Hidden line" style.')
    assert_equal(false, render_opts['DrawDepthQue'],
                 'Depth cue is turned on after choosing "Hidden line" style.')
    assert_equal(false, render_opts['ExtendLines'],
                 'Extension is turned on after choosing "Hidden line" style.')
    assert_equal(false, render_opts['DrawLineEnds'],
                 'Endpoints is turned on after choosing "Hidden line" style.')
    assert_equal(false, render_opts['JitterEdges'],
                 'Jitter is turned on after choosing "Hidden line" style.')
  end
end
