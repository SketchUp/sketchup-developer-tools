#!/usr/bin/ruby
#
# Copyright:: Copyright 2012 Trimble Navigation Ltd.
# License:: Apache License version 2.0
# Original Author:: Sandra Winstead 
#
# Regression test for Buganizer Bug #2134312

require 'test/unit'

# The main test class.
#
class TC_2134312 < Test::Unit::TestCase

  def setup
    local_path = __FILE__.slice(0,__FILE__.rindex('.'))
    @test_kmz = File.join(local_path, 'Simple_color_kmz_issue.kmz')
  end

  def teardown
    # Clean up the file so the "Save" dialog doesn't pop on close.
    3.times do
      Sketchup.undo
    end
  end

  def test_2134312
    # Start a new skp file and delete existing entities.
    Sketchup.file_new
    model = Sketchup.active_model
    ents = model.entities
    ents.clear!

    # Import the kmz and explode the imported component.
    model.import @test_kmz, false
    if ents[0].nil?
      assert(false, "Error occured when importing kmz.")
    end
    ents[0].explode

    # Count the transparent faces.
    transparent_count = 0
    if ents.nil?
      assert(false, "No entities exist in exploded component.")
    end
    ents.each do |item|
      type = item.typename
      case type
        when "Face"
          # If front material is transparent, add to transparent count.
          if item.material.alpha == 0
            transparent_count += 1
          end
          # If back material is transparent, add to transparent count.
          if item.back_material.alpha == 0
            transparent_count +=1
          end
      end
    end
    assert_equal(0, transparent_count, 'Model has transparent faces.')
  end

end
