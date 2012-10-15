#-----------------------------------------------------------------------------
#
# Copyright:: Copyright 2012 Trimble Navigation Ltd.
# License:: Apache License version 2.0
# Original Author:: Simone Nicolo 
#
# Provides tests for the preservation of texture names fixes.
# These test opens a set of SU models in a specified directory,
# exporting them to COLLADA and then checks that the textures exported
# alongside the .dae file are the right number. Then it makes sure the COLLADA
# file is coherent.
#
# Test comes with a specific set of models but more can be added.
#
#-----------------------------------------------------------------------------

require 'test/unit'

# Test class for the Texture Export sanity test
#
# The class contains one test case which will verify that texture export is
# working.
#
class TC_COLLADA_texture_export < Test::Unit::TestCase

  # Method used to set up some class variables.
  #
  # Args:
  #   None
  # Returns:
  #   None
  #
  def setup

    # Path to the supporting data for this test
    supporting_data_path = __FILE__.slice(0, __FILE__.rindex('.'))

    # Path to the SketchUp models used in this test
    @model_dir = File.join(supporting_data_path, 'models')

    # Path to where the exported files will be kept
    @exports_dir = File.join(supporting_data_path, 'COLLADA')

    # Get all skp files
    @arr_of_files = Dir.glob(File.join(@model_dir.to_s , '*.skp'))

    # If the exports folder does not exist, make it
    if File.exists?(@exports_dir) == false
      Dir.mkdir(@exports_dir)
    end

    # Create a date specific results folder to store output
    current_time = Time.now.strftime('%m%d%Y_%I%M%p_%S')
    @exports_dir = File.join(@exports_dir, current_time)
    Dir.mkdir(@exports_dir) if not File.exist?(@exports_dir)

    # Set the COLLADA export options here
    @dae_options_hash = { :triangulated_faces   => true,
                          :doublesided_faces    => false,
                          :edges                => false,
                          :materials_by_layer   => false,
                          :author_attribution   => false,
                          :texture_maps         => true,
                          :selectionset_only    => false,
                          :preserve_instancing  => true }

    # Determine current platform
    @platform = 'win'
    @platform = 'mac' if RUBY_PLATFORM.include? 'darwin'

    if @platform == 'win'
      @coherency_check_exe = File.join(supporting_data_path,
                                      'coherencytest_win32_x86.exe')
    end
    @error_log = File.join(@exports_dir, 'error.log')

  end


  # Method to clean up after test is done
  #
  # Args:
  #   None
  # Returns:
  #   None
  #
  def teardown
    Sketchup.file_new
    # TODO (snicolo): add a way to close the models that are open. Without
    # this, on the Mac, the models you ran through the test will be left open.
    # Currently there is no Ruby method to close a model.
  end

  def coherency_check
   cmd = @coherency_check_exe + " \"#{title.to_s}\"" +
      " -log \"#{@error_log}\""

    system(cmd)
    log_file_lines = IO.readlines(@error_log)
    coherency_error = false

    log_file_lines.each do |line|
      if line.include?("ERROR")
        coherency_error = true
        break
      end
    end
    return coherency_error
  end

  def test_coen_fruit_stand

    model_name = 'CoenFruitStand'
    sketchup_model = File.join(@model_dir.to_s , "#{model_name}.skp")
    # Open the models
    File.chmod(0777, sketchup_model) if @platform == 'win'
    Sketchup.open_file sketchup_model
    model = Sketchup.active_model

    # Export to COLLADA
    title = File.join(@exports_dir, "#{model_name}.dae")
    model.export title,  @dae_options_hash

    # Make sure the exported dae exists
    assert(File.exist?(title), "exported dae #{title} does not exists")

    # Make sure the number of exported textures is correct
    expected_count = 21
    textures = Dir.glob(File.join(@exports_dir, "#{model_name}") +
                      "/*.{jpg,png,tif,bmp}")
    textures_count = textures.size
    assert_equal(expected_count, textures_count,
                 "number of exported textures was #{textures_count}" +
                 " instead of #{expected_count}")

    # On Windows use the coherency_checker to validate the .dae file
    coherency_error = coherency_check(title) if @platform.equal? 'win'
    assert((not coherency_error), "Found a coherency error for file #{title}")

  end

  def test_dae_export_test
    # In this test we also check to make sure the texture names have been
    # correctly applied to the texture files.
    expected_texture_names = {
            '________.jpg' => true,
            '_________0.jpg' => true,
            '__T____________-____.jpg' => true,
            'Asphalt_Stamped_Brick_.jpg' => true,
            'Carpet_Pattern_LeafSquares_Tan_.jpg' => true,
            'Carpet_Pattern_LeafSquares_Tan__0.jpg' => true,
            'Europa_ischer_Nussbaum.tif' => true,
            'Funky_~____________-__________.____.jpg' => true,
            'Material.WithPeriod.jpg' => true,
            'material_3.jpg' => true,
            'TestTextureSameName1.jpg' => true,
            'TestTextureSameName2.jpg' => true,
            'Texture_With_Spaces.jpg' => true }

    model_name = 'dae_export_test'
    sketchup_model = File.join(@model_dir.to_s , "#{model_name}.skp")
    # Open the models
    File.chmod(0777, sketchup_model) if @platform == 'win'
    Sketchup.open_file sketchup_model
    model = Sketchup.active_model

    # Export to COLLADA
    title = File.join(@exports_dir, "#{model_name}.dae")
    model.export title,  @dae_options_hash

    # Make sure the exported dae exists
    assert(File.exist?(title), "exported dae #{title} does not exists")

    # Make sure the number of exported textures is correct
    expected_count = 13
    textures = Dir.glob(File.join(@exports_dir, "#{model_name}") +
                      "/*.{jpg,png,tif,bmp}")
    textures_count = textures.size
    assert_equal(expected_count, textures_count,
                 "number of exported textures was #{textures_count}" +
                 " instead of #{expected_count}")

    # Check that the texture filenames are as expected.
    textures.each do |tex|
      assert(expected_texture_names[File.basename(tex)],
             "The texture filename #{tex} was not expected")
    end
    # TODO(snicolo): also check the content of the COLLADA file for the
    # Texture and Material names.

    # On Windows use the coherency_checker to validate the .dae file
    coherency_error = coherency_check(title) if @platform.equal? 'win'
    assert((not coherency_error), "Found a coherency error for file #{title}")

  end

  def test_distorted

    model_name = 'distorted'
    sketchup_model = File.join(@model_dir.to_s , "#{model_name}.skp")
    # Open the models
    File.chmod(0777, sketchup_model) if @platform == 'win'
    Sketchup.open_file sketchup_model
    model = Sketchup.active_model

    # Export to COLLADA
    title = File.join(@exports_dir, "#{model_name}.dae")
    model.export title,  @dae_options_hash

    # Make sure the exported dae exists
    assert(File.exist?(title), "exported dae #{title} does not exists")

    # Make sure the number of exported textures is correct
    expected_count = 3
    textures = Dir.glob(File.join(@exports_dir, "#{model_name}") +
                      "/*.{jpg,png,tif,bmp}")
    textures_count = textures.size
    assert_equal(expected_count, textures_count,
                 "number of exported textures was #{textures_count}" +
                 "instead of #{expected_count}")

    # On Windows use the coherency_checker to validate the .dae file
    coherency_error = coherency_check(title) if @platform.equal? 'win'
    assert((not coherency_error), "Found a coherency error for file #{title}")

  end

  def test_google_earth_textures

    model_name = 'GoogleEarthTextures'
    sketchup_model = File.join(@model_dir.to_s , "#{model_name}.skp")
    # Open the models
    File.chmod(0777, sketchup_model) if @platform == 'win'
    Sketchup.open_file sketchup_model
    model = Sketchup.active_model

    # Export to COLLADA
    title = File.join(@exports_dir, "#{model_name}.dae")
    model.export title,  @dae_options_hash

    # Make sure the exported dae exists
    assert(File.exist?(title), "exported dae #{title} does not exists")

    # Make sure the number of exported textures is correct
    expected_count = 9
    textures = Dir.glob(File.join(@exports_dir, "#{model_name}") +
                      "/*.{jpg,png,tif,bmp}")
    textures_count = textures.size
    assert_equal(expected_count, textures_count,
                 "number of exported textures was #{textures_count}" +
                 " instead of #{expected_count}")

    # On Windows use the coherency_checker to validate the .dae file
    coherency_error = coherency_check(title) if @platform.equal? 'win'
    assert((not coherency_error), "Found a coherency error for file #{title}")

  end

  def test_unicode

    model_name = 'unicode'
    sketchup_model = File.join(@model_dir.to_s , "#{model_name}.skp")
    # Open the models
    File.chmod(0777, sketchup_model) if @platform == 'win'
    Sketchup.open_file sketchup_model
    model = Sketchup.active_model

    # Export to COLLADA
    title = File.join(@exports_dir, "#{model_name}.dae")
    model.export title,  @dae_options_hash

    # Make sure the exported dae exists
    assert(File.exist?(title), "exported dae #{title} does not exists")

    # Make sure the number of exported textures is correct
    expected_count = 5
    textures = Dir.glob(File.join(@exports_dir, "#{model_name}") +
                      "/*.{jpg,png,tif,bmp}")
    textures_count = textures.size
    assert_equal(expected_count, textures_count,
                 "number of exported textures was #{textures_count}" +
                 " instead of #{expected_count}")

    # On Windows use the coherency_checker to validate the .dae file
    coherency_error = coherency_check(title) if @platform.equal? 'win'
    assert((not coherency_error), "Found a coherency error for file #{title}")

  end

  def test_why_underscores

    model_name = 'why_underscores'
    sketchup_model = File.join(@model_dir.to_s , "#{model_name}.skp")
    # Open the models
    File.chmod(0777, sketchup_model) if @platform == 'win'
    Sketchup.open_file sketchup_model
    model = Sketchup.active_model

    # Export to COLLADA
    title = File.join(@exports_dir, "#{model_name}.dae")
    model.export title,  @dae_options_hash

    # Make sure the exported dae exists
    assert(File.exist?(title), "exported dae #{title} does not exists")

    # Make sure the number of exported textures is correct
    expected_count = 1
    textures = Dir.glob(File.join(@exports_dir, "#{model_name}") +
                      "/*.{jpg,png,tif,bmp}")
    textures_count = textures.size
    assert_equal(expected_count, textures_count,
                 "number of exported textures was #{textures_count}" +
                 " instead of #{expected_count}")

    # On Windows use the coherency_checker to validate the .dae file
    coherency_error = coherency_check(title) if @platform.equal? 'win'
    assert((not coherency_error), "Found a coherency error for file #{title}")

  end

end
