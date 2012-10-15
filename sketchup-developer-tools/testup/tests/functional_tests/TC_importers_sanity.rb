#-----------------------------------------------------------------------------
#
# Copyright:: Copyright 2012 Trimble Navigation Ltd.
# License:: Apache License version 2.0
# Original Author:: Tricia Stahr 
#
# Provides a high level sanity test of the SketchUp importers by importing
# a specific set of files, counting the number of entities in the model
# and comparing those numbers against expected values.
#
# If the number of entities is unexpected, the script asserts.
#-----------------------------------------------------------------------------
require 'test/unit'
require 'registry' if not RUBY_PLATFORM.include? 'darwin'

# Test class for the SU Importers sanity test
#
# The class contains one test case which will verify that the importers
# are working at a high level.
#
class TC_importers_sanity < Test::Unit::TestCase

  # Method used to set up some class variables.
  # Args:
  #   None
  # Returns:
  #    None
  #
  def setup
    @supporting_data_dir = __FILE__.slice(0, __FILE__.rindex('.'))

    # Create array of available importers based on whether Pro or Free
    # is being run
    @arr_of_importers = ['dae', 'kmz', '3ds', 'skp', 'dem']
    @arr_of_importers += ['dwg','dxf'] if Sketchup.is_pro?

    # Create an array of importers for which we will need to set options
    @arr_of_importers_with_options = @arr_of_importers - ['skp','kmz','dxf']

    # Set class SU variables
    @model = Sketchup.active_model
    @defs = @model.definitions
    @entities = @model.entities
    @materials = @model.materials
    @layers = @model.layers
    @su_version = Sketchup.version.split('.')[0]

    # Determine current platform
    @platform = 'win'
    @platform = 'mac' if RUBY_PLATFORM.include? 'darwin'
  end


  # Method to clean up after test is done
  #
  # Args:
  #   None
  # Returns:
  #   None
  #
  def teardown
    clear_data

    # Start a new file to assure that no test data is left in model
    Sketchup.file_new
  end

  # Method to clear data between imports
  #
  # Args:
  #   None
  # Returns:
  #   None
  #
  def clear_data

    # Initialize counters
    @nr_edges = @nr_faces = @nr_cinstances = @nr_groups = @nr_images =
    @nr_dimensions = @nr_texts = @nr_sectionplanes = @nr_clines = @nr_cpoints =
    @nr_cdefinitions = @nr_layers = @nr_materials = @nr_pages =
    @nr_transparent_mats = 0
    @arr_top_level_entities = []

    # Purge model entities
    @model.entities.clear!
    @defs.purge_unused
    @materials.purge_unused
    @layers.purge_unused
    #TODO(tricias): add a way to clear the model location
  end


  # Method to set the import options for importers on the PC.  Options need
  # to be set so that the statistics we gather will always be predictable.
  #
  # Args:
  #   None
  # Returns:
  #   None
  #
  def set_win_options

    # For each importer, create a hash containing the path to where the
    # importer options are stored in the registry.
    importers_paths = Hash.new()
    importers_paths = {
        '3ds' =>  'Software\Google\SketchUp 3DS Importer',
        'dwg' => "Software\\Google\\SketchUp#{@su_version}\\Preferences",
        'dxf' => "Software\\Google\\SketchUp#{@su_version}\\Preferences",
        'dae' =>  "Software\\Google\\SketchUp#{@su_version}\\" +
                  "com.google.sketchup.import.dae",
        'kmz' =>  "Software\\Google\\SketchUp#{@su_version}\\" +
                  "com.google.sketchup.import.dae",
        'dem' => 'Software\Google\SketchUp DEM Importer'
        }

    # For each importer, create a hash containing the key names and key values
    # associated with each importer option
    importer_settings = Hash.new()
    importer_settings['3ds'] = {
        'FileUnits' => 1,
        'MergeCoplanar' => 0,
        'SoftEdges' => 0}
    importer_settings['dwg'] = {
        'ImportMergeFaces' => 0,
        'ImportOrientFaces' => 1,
        'ImportDwgUnits' => 1,
        'DwgImportPreserveOrigin' => 0}
    importer_settings['dae'] = {
        'ImportMergeCoplanarFaces' => 0,
        'ImportValidateDAE' => 1}
    importer_settings['dem'] = {
        'ErrorThreshold' =>100,
        'GenTexture' => 0,
        'HeightScale' => 1,
        'MaxPoints' => 250}

    # Initialize a counter we will use in the next loop
    nr_different_keys = 0

    # Loop through the array of importers that have options which need to be
    # set.
    @arr_of_importers_with_options.each do |importer_extension|

      # Set the registry key path
      key_path = importers_paths[importer_extension]

      # Loop through the hash containing the importer specific key names and
      # key values
      importer_settings[importer_extension].each do |key, value|

        # Set the name and value for the key we are processing
        key_name = String.new(key.to_s)
        key_value = value

        # We will write new key values to the registy and our write will fail
        # if the key does not exist in the registry.  Provide a rescue loop to
        # handle this condition.
        begin

          # Attempt to read the current key value.  If it does not exist, an
          # 'Win32::Registry::Error' error will be thrown
          k = Win32::Registry::HKEY_CURRENT_USER.open(key_path,
                                                      Win32::Registry::KEY_READ
                                                      )[key_name]

        # Rescue the 'Win32::Registry::Error' error
        rescue  Win32::Registry::Error:

          # Create the missing key
          Win32::Registry::HKEY_CURRENT_USER.create(key_path,
                                                    Win32::Registry::KEY_WRITE
                                                    ) do |reg|
            reg[key_name, Win32::Registry::REG_DWORD] = key_value
          end
        end

        # Write the value of the key to the the registry
        Win32::Registry::HKEY_CURRENT_USER.open(key_path,
                                                Win32::Registry::KEY_WRITE
                                                ) do |reg|
          reg[key_name, Win32::Registry::REG_DWORD] = key_value
        end

        # For some reason, the changes to DWG's options don't take effect
        # until the user runs the test a second time.  This could cause a false
        # failure of the test.  To workaround this, compare the original value
        # of the key to the value we want to set.  If they are different,
        # increment a counter . Based on this counter, we will decide if we
        # need to alert the user to rerun the test.
        if k.to_s != key_value.to_s and importer_extension == 'dwg'
           nr_different_keys += 1
        end
      end
    end
    # If we found that we needed to make changes to the DWG options,
    # raise an error prompting the user to rerun the test.
    if nr_different_keys > 0
      raise RuntimeError, "\n TestUp needed to set some import preferences
                    that were different than what you had previously. For them
                    to take effect, you need to rerun the test. \n"
    end
  end


  # Method to set the import options for importers on the Mac.  Options need
  # to be set so that the statistics we gather will always be predictable.
  #
  # Args:
  #   None
  # Returns:
  #   None
  #
  def set_mac_options

    # Set correct plist name depending on which version of SU is being run.
    # Note: until http://b/issue?id=2439148 is fixed, the plist name will be
    # wrong when running SU Free.
    plist_name = 'com.google.sketchuppro'
    plist_name = 'com.google.sketchupfree' if @model.get_product_family == 1

    # For each importer, create a hash containing the key names and key values
    # associated with each importer option
    importer_settings = Hash.new()
    importer_settings['3ds'] = {
        'SketchUp.Preferences.Import3DS.Units' => 1,
        'SketchUp.Preferences.Import3DS.MergeCoplanar' => 0,
        'SketchUp.Preferences.Import3DS.SoftEdges' => 0}
    importer_settings['dwg'] = {
        'SketchUp.Preferences.ImportMergeFaces' => 0,
        'SketchUp.Preferences.ImportOrientFaces' => 1,
        'SketchUp.Preferences.ImportDwgUnits' => 1,
        'SketchUp.Preferences.DwgImportPreserveOrigin' => 0}
    importer_settings['dae'] = {
        'com.google.sketchup.import.dae.ImportMergeCoplanarFaces' => 0,
        'com.google.sketchup.import.dae.ImportValidateDAE' => 1}
    importer_settings['dem'] = {
        'SketchUp.Preferences.ExportDEM.MaxError' =>10,
        'SketchUp.Preferences.ExportDEM.GenTexture' => 0,
        'SketchUp.Preferences.ExportDEM.HeightScale' => 1,
        'SketchUp.Preferences.ExportDEM.MaxPoints' => 250}

    # Set the name of a temp file we will use in the next loop
    temp_file =  "#{@supporting_data_dir}/temp_key_file"

    # Initialize a counter we will use in the next loop
    nr_different_keys = 0

    # Loop through the array of importers that need options to be set
    @arr_of_importers_with_options.each do |importer_extension|

      # Loop through the hash containing the importer specific key names and
      # key values
      importer_settings[importer_extension].each do |key, value|

        # Determine if the current value in the plist is different than the
        # value we want to set.  If they are different, we will need to
        # prompt the user to close/reopen SU.  The following code
        # will immediately write our new values to the plist.  SU's
        # importers though, don't register that new values have been
        # set until we close/reopen the app.  If we don't do this step,
        # our test could give a false negative.

        # Create a variable to hold the current plist key value
        current_key_value = nil

        # Compose a string that, when passed to the system, will read the
        # current key value and pipe the output to our temp file.  If we don't
        # create a temp file, the defaults read command would simply
        # return true or false vs giving us the key value.
        read_command="defaults read #{plist_name}#{@su_version} " +
                       "#{key} > '#{temp_file}'"

        # Pass the command string to the system to create the temp file
        system(read_command)

        # Set our current key value by opening the temp file and reading
        # the first line
        f = File.open temp_file
        first_line = f.readlines[0]
        current_key_value = first_line.chomp if first_line != nil
        f.close

        # Compare the current key value to the value we want to set.  If they
        # are different, increment a counter which keeps track of the number
        # of keys that are different.
        if current_key_value.to_s != value.to_s
           nr_different_keys += 1
        end

        # Compose a string that, when passed to the system, will write to the
        # plist, the key values we want to set.
        write_command = "defaults write #{plist_name}#{@su_version} " +
                       "#{key} #{value}"

        # Pass the command to the system to write our new values to the plist
        system(write_command)
      end
    end

    # If we found we needed to make changes to any of the importer options,
    # raise an error prompting the user to exit and relaunch SU.
    if nr_different_keys > 0
      raise RuntimeError, "\n TestUp needed to set some import preferences
                    that were different than what you had previously. For them
                    to take effect, you need to exit SU and then rerun this
                    test. \n"
    end
  end


  # Method for counting entities
  #
  # Args:
  #   object_var: a SketchUp Entity object
  # Returns:
  #   None
  #
  def count_entities(object_var)
    type = (object_var).typename
    case type
      when 'Edge'
        @nr_edges += 1
      when 'Face'
        @nr_faces += 1
      when 'ComponentInstance'
        @nr_cinstances += 1
      when 'Group'
        @nr_groups += 1
      when 'Image'
        @nr_images += 1
      when 'SectionPlane'
        @nr_sectionplanes += 1
      when 'DimensionLinear'
        @nr_dimensions += 1
      when 'DimensionRadial'
        @nr_dimensions += 1
      when 'Text'
        @nr_texts += 1
      when 'ConstructionLine'
        @nr_clines += 1
      when 'ConstructionPoint'
        @nr_cpoints += 1
    end
  end


  # Method to gather data that exists at the top level of the SU model
  # Data gathered will include some model statistics as well as an array
  # of top level SU Entity objects.
  #
  # Args:
  #   None
  # Returns:
  #   None
  #
  def gather_high_level_data

    # Count non-geometry items
    @nr_cdefinitions = @defs.length
    @nr_layers = @model.layers.length
    @nr_pages = @model.pages.count
    @nr_materials = @model.materials.length
    @materials.each do |m|
        @nr_transparent_mats += 1 if m.alpha < 1
    end

    # Count top level geometry and create an array of the top level entities
    @entities.each do |entity|
      @arr_top_level_entities.push entity
      count_entities(entity)
    end
  end


  # Method to traverse through the model hierarchy and collect statistics.
  #
  # This method loops through an array of entities passed to it.
  # If the entity is a group or component, statistics for the geometry
  # within the component/group will be collected and the entities within the
  # component/group will be added to a new array (arr_nested_entities). The
  # method will then recursively call itself passing in the array of nested
  # entities which will loop through the entities again looking for components/
  # groups, collecting statistics and creating a  new array of lower level
  # nested entities if necessary until the entire model hierarchy is traversed.
  # An array of the top level model entities is the first array passed to
  # this method.
  #
  # Args:
  #   arr_of_entities: an array of SketchUp entities
  # Returns:
  #   None
  #
  def drill_down_hierarchy(arr_of_entities)
    arr_of_entities.each do |entity|
      arr_nested_entities = []
      type = entity.typename
      case type
        when 'ComponentInstance'
          entity.definition.entities.each do |item|
            count_entities(item)

            # If the entity is a component, push all the entities in the
            # component to the array of nested entities
            arr_nested_entities.push item
        end
        when 'Group'
          entity.entities.each do |item|
            count_entities(item)

            # If the entity is a group, push all the entities in the
            # group to the array of nested entities
            arr_nested_entities.push item
          end
        end

      # Recursively call this method, passing in the current array of nested
      # entities
      drill_down_hierarchy(arr_nested_entities)
    end
  end


  # Method to import a file
  # The method includes logic for doing additional steps for the 3ds and skp
  # importers
  #
  # Args:
  #   filename: name of file to be imported
  #   filename_extension: file extension of imported file
  # Returns:
  #   None
  #
  def import_file(filename, filename_extension)

   # Import the file
   Sketchup.active_model.import(filename.to_s, false)

   # This is a hack to make 3ds/skp import work.  The problem is that the 3ds
   # and skp importers don't place the geometry in the model when imported.
   # Instead, they import the geometry as a component that needs to be
   # placed and until it is placed, no geometry shows up in the model. This
   # code finds the top most definition based on expected name and inserts it
   # into the model.  Note: for 3ds,this code only needs to be executed on Win
   # as the Mac behaves differently, directly inserting the 3ds file.
   #
   # TODO(tricias): look for a better way to do this
   if filename_extension == '3ds' and @platform == 'win'
     @defs.each do |item|

       # Find the top most definition which, for 3ds, has "skp" in the name
       if item.name.include?('skp')
         point = Geom::Point3d.new 10,20,30
         transform = Geom::Transformation.new point

         # Add an instance of the definiton
         instance = @entities.add_instance item, transform
         break
       end
     end
   end
   if filename_extension == 'skp'
     top_def_name = File.basename(filename, '.skp')
     @defs.each do |item|

       # Find the top most definition which, for skp, is the name of the model
       if item.name == top_def_name
         point = Geom::Point3d.new 10,20,30
         transform = Geom::Transformation.new point

         # Add an instance of the definiton
         instance = @entities.add_instance item, transform
         break
       end
     end
   end
  end


  # Method to create a hash of expected values for each file that we are
  # importing.
  #
  # Args:
  #   None
  # Returns:
  #   None
  #
  def create_hash_of_expected_values
    @statistics = Hash.new()
    @statistics['Cabin.dwg'] = {:edges => 4232, :faces => 1589,
        :componentinstances => 22, :groups => 0, :images => 0,
        :dimensions => 0, :texts => 0, :sectionplanes => 0, :clines => 0,
        :cpoints => 0, :compdefs => 11, :layers => 19, :materials => 8,
        :pages => 0, :transparent_mats => 0}
    @statistics['Escher.dxf'] = {:edges => 19242, :faces => 10938,
        :componentinstances => 0, :groups => 0, :images => 0,
        :dimensions => 0, :texts => 0, :sectionplanes => 0, :clines => 0,
        :cpoints => 0, :compdefs => 0, :layers => 1, :materials => 0,
        :pages => 0, :transparent_mats => 0}
    @statistics['astronautglove.3ds'] = {:edges => 1263, :faces => 842,
        :componentinstances => 2, :groups => 0, :images => 0,
        :dimensions => 0, :texts => 0, :sectionplanes => 0, :clines => 0,
        :cpoints => 0, :compdefs => 2, :layers => 1, :materials => 1,
        :pages => 0, :transparent_mats => 0}
    @statistics['RegentityAll.skp'] = {:edges => 829, :faces => 317,
        :componentinstances => 5, :groups => 1, :images => 1,
        :dimensions => 2, :texts => 18, :sectionplanes => 1, :clines => 3,
        :cpoints => 2, :compdefs => 9, :layers => 6, :materials => 8,
        :pages => 0, :transparent_mats => 2}
    @statistics['RamadaTimesSquare.kmz'] = {:edges => 1495, :faces => 1001,
        :componentinstances => 1, :groups => 0, :images => 0,
        :dimensions => 0, :texts => 0, :sectionplanes => 0, :clines => 0,
        :cpoints => 0, :compdefs => 1, :layers => 1, :materials => 67,
        :pages => 0, :transparent_mats => 0}
    @statistics['colored_box.dae'] = {:edges => 12, :faces => 6,
        :componentinstances => 1, :groups => 0, :images => 0,
        :dimensions => 0, :texts => 0, :sectionplanes => 0, :clines => 0,
        :cpoints => 0, :compdefs => 1, :layers => 1, :materials => 6,
        :pages => 0, :transparent_mats => 0}
    @statistics['7329_75m.dem'] = {:edges => 731, :faces => 482,
        :componentinstances => 1, :groups => 0, :images => 0,
        :dimensions => 0, :texts => 0, :sectionplanes => 0, :clines => 0,
        :cpoints => 0, :compdefs => 1, :layers => 1, :materials => 0,
        :pages => 0, :transparent_mats => 0}
  end


  # Verification method that does the import and verifies it is as expected.
  # It imports the data, gathers model statistics, compares the statistics
  # against expected values and asserts if there are differences.
  #
  # Args:
  #   None
  # Returns:
  #   None
  #
  def test_import_succeeded_large

    # Set import options
    set_win_options if @platform == 'win'
    set_mac_options if @platform == 'mac'

    # Create a hash of expected values for import statistics
    create_hash_of_expected_values

    # Loop through the importers available to the SU version being run
    @arr_of_importers.each do |importer_extension|

      # Create an array of the available files to import
      @arr_of_files = Dir.glob(File.join("#{@supporting_data_dir.to_s}" +
                      "/*.#{importer_extension}"))

      # Loop through the available files to import
      @arr_of_files.each do |file_to_import|

        # Clear model and reset counters
        clear_data

        # Import the current file
        import_file(file_to_import, importer_extension)

        # Count the data in the SU model
        gather_high_level_data
        drill_down_hierarchy(@arr_top_level_entities)

        # Based on the current file name, read the hash of expected values
        # and set the expected values for the file being imported
        base_file_name = File.basename(file_to_import)
        expected_edges = @statistics[base_file_name][:edges]
        expected_faces = @statistics[base_file_name][:faces]
        expected_cinstances = @statistics[base_file_name][:componentinstances]
        expected_groups = @statistics[base_file_name][:groups]
        expected_images = @statistics[base_file_name][:images]
        expected_dimensions = @statistics[base_file_name][:dimensions]
        expected_texts = @statistics[base_file_name][:texts]
        expected_sectionplanes = @statistics[base_file_name][:sectionplanes]
        expected_clines = @statistics[base_file_name][:clines]
        expected_cpoints = @statistics[base_file_name][:cpoints]
        expected_cdefs = @statistics[base_file_name][:compdefs]
        expected_layers = @statistics[base_file_name][:layers]
        expected_materials = @statistics[base_file_name][:materials]
        expected_pages = @statistics[base_file_name][:pages]
        expected_trans_mats = @statistics[base_file_name][:transparent_mats]

        # Compose assert error message
        error_msg = "\nFor file to import #{file_to_import.to_s} ... \n
            We expected #{expected_edges} edges and got #{@nr_edges}
            We expected #{expected_faces} faces and got #{@nr_faces}
            We expected #{expected_cinstances} cinstances and got " +
                "#{@nr_cinstances}
            We expected #{expected_groups} groups and got #{@nr_groups}
            We expected #{expected_images} images and got #{@nr_images}
            We expected #{expected_dimensions} dimensions and got " +
                "#{@nr_dimensions}
            We expected #{expected_texts} text entities and got #{@nr_texts}
            We expected #{expected_sectionplanes} section planes and got " +
                "#{@nr_sectionplanes}
            We expected #{expected_clines} construction lines and got " +
                "#{@nr_clines}
            We expected #{expected_cpoints} construction points and got " +
                "#{@nr_cpoints}
            We expected #{expected_cdefs} component definitions and got " +
                "#{@nr_cdefinitions}
            We expected #{expected_layers} layers and got #{@nr_layers}
            We expected #{expected_materials} materials and got " +
               "#{@nr_materials}
            We expected #{expected_pages} pages and got #{@nr_pages}
            We expected #{expected_trans_mats} transparent materials and " +
                "got #{@nr_transparent_mats} \n"

        # Assert if the expected values differ from the actual values
        assert_equal( [expected_edges, expected_faces,
            expected_cinstances, expected_groups,
            expected_images, expected_dimensions, expected_texts,
            expected_sectionplanes, expected_clines, expected_cpoints,
            expected_cdefs, expected_layers, expected_materials,
            expected_pages, expected_trans_mats],
                      [@nr_edges, @nr_faces, @nr_cinstances,
            @nr_groups, @nr_images, @nr_dimensions, @nr_texts,
            @nr_sectionplanes, @nr_clines, @nr_cpoints, @nr_cdefinitions,
            @nr_layers, @nr_materials, @nr_pages, @nr_transparent_mats],
            error_msg)
      end
    end
  end

end
