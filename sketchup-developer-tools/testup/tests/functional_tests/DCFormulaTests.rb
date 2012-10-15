#
# Copyright:: Copyright 2012 Trimble Navigation Ltd.
# License:: Apache License version 2.0
# Original Author:: Simone Nicolo 
#
# This Script is used for testing the Formula Parser, and the various
# functions available for Dynamic Component.
#
# These tests are going to be used in conjunction with the testup framework

require 'sketchup.rb'
require 'test/unit'

#
# This Script is used for testing the Formula Parser, and the various functions
# available through it for Dynamic Components.
#
# Note:
#   $dc_observers is a global created inside dcobservers.rb. We can use its
#   get_class_by_version method to return a reference to the appropriate
#   instance of the DCClass object. In other words, if there are several
#   versions of DCs running on the same machine, this is the way to find
#   out the correct one to run our formulas inside of.

class DCFormulaTests < Test::Unit::TestCase
  
  @@DC_TRUE = 1.0
  @@DC_FALSE = 0.0
  @@ACCURACY = 6

  def setup
    #Assets for this test case
    @test_model = 'formulatest.skp'
    @local_path = __FILE__.slice(0, __FILE__.rindex('.'))
    #puts "path : #{@local_path}"
    @test_model_path = @local_path + '/' + @test_model
    #puts "test model path : #{@test_model_path}"
    @dc = nil
    @entity = nil
    @correct = nil
    @returned = nil
    @markup = nil
    open_test_model
  end

  # This function rounds floating point numbers to the specified decimal place
  #
  # Args:
  #   None
  #
  # Returns:
  #   returns a float rounded to the specified decimal place
  def round_float(fp_number, d_place)
    assert_nothing_raised do
      return (fp_number * 10**d_place).round.to_f / 10**d_place
    end
  end


  # This function open the test model we rely on and sets the class variables
  # @dc and @entity.
  #
  # Args:
  #   None
  # 
  # Returns:
  #   None  
  def open_test_model
    assert_nothing_raised do
      Sketchup.open_file @test_model_path
      entities = Sketchup.active_model.entities
      @entity = entities[0]
      if @entity.typename == "ComponentInstance"  
        @dc = $dc_observers.get_class_by_version(@entity) 
      end
    end
  end

  # This function prepares the results to be compared by truncating floating 
  # points numbers to the value specified in @@ACCURACY and puts them in the
  # class variables @correct and @returned
  # 
  # Args:
  #   None
  # 
  # Returns:
  #   None
  def prepare_result
    assert_nothing_raised do
      if @correct.kind_of? Integer
        @returned = @returned.to_f
        @correct = @correct.to_f
      elsif @correct.kind_of? Float
        @returned = round_float(@returned.to_f, @@ACCURACY)
        @correct = round_float(@correct, @@ACCURACY)
      else
        @returned = @returned
      end
      #debug info
      #puts "expected: #{@correct} - returned: #{@returned} - markup: #{@markup}"
    end
  end

  # This function runs test for the supported operators 
  #
  # In order to add a test you can use the following template
  #   ------------------------------------------------------ 
  #   @returned, @markup = @dc.parse_formula('<FORMULA TO BE PARSED>',
  #                                          @entity)
  #   @correct = <RESULT/MARKUP YOU EXPECT>
  #   prepare_result #this step is used to avoid computer arithmetic errors 
  #   assert_equal(@correct, @returned, "The expected result: #{@correct} does
  #                not match the returned result #{@returned}")
  #   assert_equal(@correct, @markup, "The expected result: #{@correct} does
  #                not match the returned markup #{@markup}")
  #   ------------------------------------------------------
  #
  # Args:
  #   None
  # Returns:
  #   None
  def test_supported_operators
    
      for i in (-7..7)
        @returned, @markup = @dc.parse_formula(i.to_s + '*-1', @entity)
        @correct = (-1*i)
        prepare_result
        assert_equal(@correct, @returned, "The expected result: #{@correct} 
                     does not match the returned result #{@returned}")
      end 

      @returned, @markup = @dc.parse_formula('-5*5', @entity)
      @correct = -25.0
      prepare_result 
      assert_equal(@correct, @returned, "The expected result: #{@correct} does
                   not match the returned result #{@returned}")
      
      @returned, @markup = @dc.parse_formula('"Scott" & 25', @entity)
      @correct = "Scott25"
      prepare_result 
      assert_equal(@correct, @returned, "The expected result: #{@correct} does
                   not match the returned result #{@returned}")
      
      @returned, @markup = @dc.parse_formula('"Scott" & "25"', @entity)
      @correct = "Scott25"
      prepare_result 
      assert_equal(@correct, @returned, "The expected result: #{@correct} does
                   not match the returned result #{@returned}")
      
      @returned, @markup = @dc.parse_formula('"Scott" & "-25"', @entity)
      @correct = "Scott-25"
      prepare_result 
      assert_equal(@correct, @returned, "The expected result: #{@correct} does
                   not match the returned result #{@returned}")
      
      @returned, @markup = @dc.parse_formula('"Scott" & "&25"', @entity)
      @correct = "Scott&25"
      prepare_result 
      assert_equal(@correct, @returned, "The expected result: #{@correct} does
                   not match the returned result #{@returned}")
      
      @returned, @markup = @dc.parse_formula('"Scott" & "\""', @entity)
      @correct = 'Scott"'
      prepare_result 
      assert_equal(@correct, @returned, "The expected result: #{@correct} does
                   not match the returned result #{@returned}")
      
      @returned, @markup = @dc.parse_formula('"Scott" & "*100"', @entity)
      @correct = "Scott*100"
      prepare_result 
      assert_equal(@correct, @returned, "The expected result: #{@correct} does
                   not match the returned result #{@returned}")
      
      @returned, @markup = @dc.parse_formula('"Scott" & "/100"', @entity)
      @correct = "Scott/100"
      prepare_result 
      assert_equal(@correct, @returned, "The expected result: #{@correct} does
                   not match the returned result #{@returned}")
      
      @returned, @markup = @dc.parse_formula('"Scott" & "+25"', @entity)
      @correct = "Scott+25"
      prepare_result 
      assert_equal(@correct, @returned, "The expected result: #{@correct} does
                   not match the returned result #{@returned}")
      
      @returned, @markup = @dc.parse_formula('"+25" & "Scott"', @entity)
      @correct = "+25Scott"
      prepare_result 
      assert_equal(@correct, @returned, "The expected result: #{@correct} does
                   not match the returned result #{@returned}")
      
      @returned, @markup = @dc.parse_formula('"+25" & "+Scott" & "+5"', @entity)
      @correct = "+25+Scott+5"
      prepare_result 
      assert_equal(@correct, @returned, "The expected result: #{@correct} does
                   not match the returned result #{@returned}")
      
      @returned, @markup = @dc.parse_formula('"+25^" & "+Scott^" & "+5^"',
                                             @entity)
      @correct = "+25^+Scott^+5^"
      prepare_result 
      assert_equal(@correct, @returned, "The expected result: #{@correct} does
                   not match the returned result #{@returned}")
      
      @returned, @markup = @dc.parse_formula('"Scott" & "(100"', @entity)
      @correct = "Scott(100"
      prepare_result 
      assert_equal(@correct, @returned, "The expected result: #{@correct} does
                   not match the returned result #{@returned}")
      
      @returned, @markup = @dc.parse_formula('"Scott" & ")100"', @entity)
      @correct = "Scott)100"
      prepare_result 
      assert_equal(@correct, @returned, "The expected result: #{@correct} does
                   not match the returned result #{@returned}")
      
      @returned, @markup = @dc.parse_formula('UPPER("(Scott" & "100)")',
                                             @entity)
      @correct = "(SCOTT100)"
      prepare_result 
      assert_equal(@correct, @returned, "The expected result: #{@correct} does
                   not match the returned result #{@returned}")
      
      @returned, @markup = @dc.parse_formula('UPPER("(Scott" & "100)a")',
                                             @entity)
      @correct = "(SCOTT100)A"
      prepare_result 
      assert_equal(@correct, @returned, "The expected result: #{@correct} does
                   not match the returned result #{@returned}")
      
      @returned, @markup = @dc.parse_formula('5*(5+1)', @entity)
      @correct = 30.0
      prepare_result 
      assert_equal(@correct, @returned, "The expected result: #{@correct} does
                   not match the returned result #{@returned}")
      
      @returned, @markup = @dc.parse_formula('LENX', @entity)
      @correct = @dc.get_attribute_value(@entity, 'LENX')
      prepare_result 
      assert_equal(@correct, @returned, "The expected result: #{@correct} does
                   not match the returned result #{@returned}")

      @returned, @markup = @dc.parse_formula('LENY', @entity)
      @correct = @dc.get_attribute_value(@entity, 'LENY')
      prepare_result 
      assert_equal(@correct, @returned, "The expected result: #{@correct} does
                   not match the returned result #{@returned}")

      @returned, @markup = @dc.parse_formula('LENZ', @entity)
      @correct = @dc.get_attribute_value(@entity, 'LENZ')
      prepare_result 
      assert_equal(@correct, @returned, "The expected result: #{@correct} does
                   not match the returned result #{@returned}")

      @returned, @markup = @dc.parse_formula('X', @entity)
      @correct = @dc.get_attribute_value(@entity, 'X')
      prepare_result 
      assert_equal(@correct, @returned, "The expected result: #{@correct} does
                   not match the returned result #{@returned}")

      @returned, @markup = @dc.parse_formula('Y', @entity)
      @correct = @dc.get_attribute_value(@entity, 'Y')
      prepare_result 
      assert_equal(@correct, @returned, "The expected result: #{@correct} does
                   not match the returned result #{@returned}")

      @returned, @markup = @dc.parse_formula('Z', @entity)
      @correct = @dc.get_attribute_value(@entity, 'Z')
      prepare_result 
      assert_equal(@correct, @returned, "The expected result: #{@correct} does
                   not match the returned result #{@returned}")
      
      @returned, @markup = @dc.parse_formula('ROTX', @entity)
      @correct = @dc.get_attribute_value(@entity, 'ROTX')
      prepare_result 
      assert_equal(@correct, @returned, "The expected result: #{@correct} does
                   not match the returned result #{@returned}")

      @returned, @markup = @dc.parse_formula('ROTY', @entity)
      @correct = @dc.get_attribute_value(@entity, 'ROTY')
      prepare_result 
      assert_equal(@correct, @returned, "The expected result: #{@correct} does
                   not match the returned result #{@returned}")

      @returned, @markup = @dc.parse_formula('ROTZ', @entity)
      @correct = @dc.get_attribute_value(@entity, 'ROTZ')
      prepare_result 
      assert_equal(@correct, @returned, "The expected result: #{@correct} does
                   not match the returned result #{@returned}")

      @returned, @markup = @dc.parse_formula('1+5*10/2-3', @entity)
      @correct = 23.0
      prepare_result 
      assert_equal(@correct, @returned, "The expected result: #{@correct} does
                   not match the returned result #{@returned}")
      
      @returned, @markup = @dc.parse_formula('(((((1)+5)*10)/2)-3)', @entity)
      @correct = 27.0
      prepare_result 
      assert_equal(@correct, @returned, "The expected result: #{@correct} does
                   not match the returned result #{@returned}")
      
      @returned, @markup = @dc.parse_formula('(1+(5*(10/(5+(-3)))))', @entity)
      @correct = 26.0
      prepare_result 
      assert_equal(@correct, @returned, "The expected result: #{@correct} does
                   not match the returned result #{@returned}")
      
      @returned, @markup = @dc.parse_formula('5/(-1) + (-1)*(-2)', @entity)
      @correct = -3.0
      prepare_result 
      assert_equal(@correct, @returned, "The expected result: #{@correct} does
                   not match the returned result #{@returned}")
      
      @returned, @markup = @dc.parse_formula('-(100)', @entity)
      @correct = -100.0
      prepare_result 
      assert_equal(@correct, @returned, "The expected result: #{@correct} does
                   not match the returned result #{@returned}")
      
      @returned, @markup = @dc.parse_formula('()-(100)', @entity)
      @correct = -100.0
      prepare_result 
      assert_equal(@correct, @returned, "The expected result: #{@correct} does
                   not match the returned result #{@returned}")
      
      @returned, @markup = @dc.parse_formula('-(100)-(100)', @entity)
      @correct = -200.0
      prepare_result 
      assert_equal(@correct, @returned, "The expected result: #{@correct} does
                   not match the returned result #{@returned}")

      @returned, @markup = @dc.parse_formula('-(100)-+(100)', @entity)
      @correct = -200.0
      prepare_result 
      assert_equal(@correct, @returned, "The expected result: #{@correct} doe
                   not match the returned result #{@returned}")
      
      @returned, @markup = @dc.parse_formula('-(-100)--(100)', @entity)
      @correct = 200.0
      prepare_result 
      assert_equal(@correct, @returned, "The expected result: #{@correct} does
                   not match the returned result #{@returned}")
      
      @returned, @markup = @dc.parse_formula('300-msrp', @entity)
      @correct = 150.0
      prepare_result 
      assert_equal(@correct, @returned, "The expected result: #{@correct} does
                   not match the returned result #{@returned}")

      @returned, @markup = @dc.parse_formula('300-(msrp)', @entity)
      @correct = 150.0
      prepare_result 
      assert_equal(@correct, @returned, "The expected result: #{@correct} does
                   not match the returned result #{@returned}")
      
      @returned, @markup = @dc.parse_formula('(300)-((msrp))', @entity)
      @correct = 150.0
      prepare_result 
      assert_equal(@correct, @returned, "The expected result: #{@correct} does
                   not match the returned result #{@returned}")

      @returned, @markup = @dc.parse_formula('(300)-((+msrp))', @entity)
      @correct = 150.0
      prepare_result 
      assert_equal(@correct, @returned, "The expected result: #{@correct} does
                   not match the returned result #{@returned}")

      @returned, @markup = @dc.parse_formula('-msrp', @entity)
      @correct = -150.0
      prepare_result 
      assert_equal(@correct, @returned, "The expected result: #{@correct} does
                   not match the returned result #{@returned}")

      @returned, @markup = @dc.parse_formula('27>26.9', @entity)
      @correct = @@DC_TRUE
      prepare_result 
      assert_equal(@correct, @returned, "The expected result: #{@correct} does
                   not match the returned result #{@returned}")

      @returned, @markup = @dc.parse_formula('27<=26.99', @entity)
      @correct = @@DC_FALSE
      prepare_result 
      assert_equal(@correct, @returned, "The expected result: #{@correct} does
                   not match the returned result #{@returned}")

      @returned, @markup = @dc.parse_formula('249<(msrp+100)', @entity)
      @correct = @@DC_TRUE
      prepare_result 
      assert_equal(@correct, @returned, "The expected result: #{@correct} doe
                   not match the returned result #{@returned}")

      @returned, @markup = @dc.parse_formula('249>(msrp+100)', @entity)
      @correct = @@DC_FALSE
      prepare_result 
      assert_equal(@correct, @returned, "The expected result: #{@correct} does
                   not match the returned result #{@returned}")

      @returned, @markup = @dc.parse_formula('250>=(msrp+100)', @entity)
      @correct = @@DC_TRUE
      prepare_result 
      assert_equal(@correct, @returned, "The expected result: #{@correct} does
                   not match the returned result #{@returned}")

      @returned, @markup = @dc.parse_formula('IF(100.0<(14.5+6),1,0)', @entity)
      @correct = @@DC_FALSE
      prepare_result 
      assert_equal(@correct, @returned, "The expected result: #{@correct} does
                   not match the returned result #{@returned}")

      @returned, @markup = @dc.parse_formula('IF(100<(14.5+6),1,0)', @entity)
      @correct = @@DC_FALSE
      prepare_result 
      assert_equal(@correct, @returned, "The expected result: #{@correct} does
                   not match the returned result #{@returned}")

      @returned, @markup = @dc.parse_formula('IF(100<(20.5),1,0)', @entity)
      @correct = @@DC_FALSE
      prepare_result 
      assert_equal(@correct, @returned, "The expected result: #{@correct} does
                   not match the returned result #{@returned}")

      @returned, @markup = @dc.parse_formula('IF(100<20.5,1,0)', @entity)
      @correct = @@DC_FALSE
      prepare_result 
      assert_equal(@correct, @returned, "The expected result: #{@correct} does
                   not match the returned result #{@returned}")

      @returned, @markup = @dc.parse_formula('IF(100.0<(14.5+6),1,0)', @entity)
      @correct = @@DC_FALSE
      prepare_result 
      assert_equal(@correct, @returned, "The expected result: #{@correct} does
                   not match the returned result #{@returned}")

      @returned, @markup = @dc.parse_formula('IF(100.0<(20.5),1,0)', @entity)
      @correct = @@DC_FALSE
      prepare_result 
      assert_equal(@correct, @returned, "The expected result: #{@correct} does
                   not match the returned result #{@returned}")

      @returned, @markup = @dc.parse_formula('IF(100.0<20.5,1,0)', @entity)
      @correct = @@DC_FALSE
      prepare_result 
      assert_equal(@correct, @returned, "The expected result: #{@correct} does
                   not match the returned result #{@returned}")

      @returned, @markup = @dc.parse_formula('100.0<20.5', @entity)
      @correct = @@DC_FALSE
      prepare_result 
      assert_equal(@correct, @returned, "The expected result: #{@correct} does
                   not match the returned result #{@returned}")

      @returned, @markup = @dc.parse_formula('100.0<20', @entity)
      @correct = @@DC_FALSE
      prepare_result 
      assert_equal(@correct, @returned, "The expected result: #{@correct} does
                   not match the returned result #{@returned}")

      @returned, @markup = @dc.parse_formula('100<20.5', @entity)
      @correct = @@DC_FALSE
      prepare_result 
      assert_equal(@correct, @returned, "The expected result: #{@correct} does
                   not match the returned result #{@returned}")

      @returned, @markup = @dc.parse_formula('100<20', @entity)
      @correct = @@DC_FALSE
      prepare_result 
      assert_equal(@correct, @returned, "The expected result: #{@correct} does
                   not match the returned result #{@returned}")

      @returned, @markup = @dc.parse_formula('100.0>20', @entity)
      @correct = @@DC_TRUE
      prepare_result 
      assert_equal(@correct, @returned, "The expected result: #{@correct} does
                   not match the returned result #{@returned}")

      @returned, @markup = @dc.parse_formula('100.0=20', @entity)
      @correct = @@DC_FALSE
      prepare_result 
      assert_equal(@correct, @returned, "The expected result: #{@correct} does
                   not match the returned result #{@returned}")
   
      @returned, @markup = @dc.parse_formula('100.0<>20', @entity)
      @correct = @@DC_TRUE
      prepare_result 
      assert_equal(@correct, @returned, "The expected result: #{@correct} does
                   not match the returned result #{@returned}")

      @returned, @markup = @dc.parse_formula('27>=(-26.8)', @entity)
      @correct = @@DC_TRUE
      prepare_result 
      assert_equal(@correct, @returned, "The expected result: #{@correct} does
                   not match the returned result #{@returned}")

      @returned, @markup = @dc.parse_formula('27>-26.8', @entity)
      @correct = @@DC_TRUE
      prepare_result 
      assert_equal(@correct, @returned, "The expected result: #{@correct} does
                   not match the returned result #{@returned}")

      @returned, @markup = @dc.parse_formula('-0 > 0', @entity)
      @correct = @@DC_FALSE
      prepare_result 
      assert_equal(@correct, @returned, "The expected result: #{@correct} does
                   not match the returned result #{@returned}")

      @returned, @markup = @dc.parse_formula('0 <= -0', @entity)
      @correct = @@DC_TRUE
      prepare_result 
      assert_equal(@correct, @returned, "The expected result: #{@correct} does
                   not match the returned result #{@returned}")

      @returned, @markup = @dc.parse_formula('0 >= -0', @entity)
      @correct = @@DC_TRUE
      prepare_result 
      assert_equal(@correct, @returned, "The expected result: #{@correct} does
                   not match the returned result #{@returned}")

      @returned, @markup = @dc.parse_formula('123.0/0.0', @entity)
      @correct = "<span class=subformula-error>DIV/0!</span> /0.0"
      prepare_result 
      assert_equal(@correct, @markup, "The expected result: #{@correct} does
                   not match the returned markup #{@markup}")  
  
  end


  # this function runs test for specific dc functions 
  #
  # in order to add a test you can use the following template
  #   ------------------------------------------------------ 
  #   @returned, @markup = @dc.parse_formula('<FORMULA TO BE PARSED>', @entity)
  #   @correct = <RESULT/MARKUP YOU EXPECT>
  #   prepare_result #this step is used to avoid computer arithmetic errors 
  #   assert_equal(@correct, @returned, "the expected result: #{@correct} does
  #                not match the returned result #{@returned}")
  #   assert_equal(@correct, @markup, "the expected result: #{@correct} does
  #                not match the returned markup #{@markup}")
  #   ------------------------------------------------------
  #
  # args:
  #   none
  # returns:
  #   none
  def test_specific_functions

      @returned, @markup = @dc.parse_formula('current("lenx")', @entity)
      @correct = @dc.get_attribute_value(@entity, 'lenx') 
      prepare_result 
      assert_equal(@correct, @returned, "the expected result: #{@correct} does
                   not match the returned result #{@returned}")  
   
      @returned, @markup = @dc.parse_formula('current("leny")', @entity)
      @correct = @dc.get_attribute_value(@entity, 'leny') 
      prepare_result 
      assert_equal(@correct, @returned, "the expected result: #{@correct} does
                   not match the returned result #{@returned}")  
      
      @returned, @markup = @dc.parse_formula('current("lenz")', @entity)
      @correct = @dc.get_attribute_value(@entity, 'lenz') 
      prepare_result 
      assert_equal(@correct, @returned, "the expected result: #{@correct} does
                   not match the returned result #{@returned}")

      @returned, @markup = @dc.parse_formula('current("rotx")', @entity)
      @correct = @dc.get_attribute_value(@entity, 'rotx') 
      prepare_result 
      assert_equal(@correct, @returned, "the expected result: #{@correct} does
                   not match the returned result #{@returned}")  
   
      @returned, @markup = @dc.parse_formula('current("roty")', @entity)
      @correct = @dc.get_attribute_value(@entity, 'roty') 
      prepare_result 
      assert_equal(@correct, @returned, "the expected result: #{@correct} does
                   not match the returned result #{@returned}")  
      
      @returned, @markup = @dc.parse_formula('current("rotz")', @entity)
      @correct = @dc.get_attribute_value(@entity, 'rotz') 
      prepare_result 
      assert_equal(@correct, @returned, "the expected result: #{@correct} does
                   not match the returned result #{@returned}")

      @returned, @markup = @dc.parse_formula('current("x")', @entity)
      @correct = @dc.get_attribute_value(@entity, 'x')
      prepare_result 
      assert_equal(@correct, @returned, "the expected result: #{@correct} does
                   not match the returned result #{@returned}")

      @returned, @markup = @dc.parse_formula('current("y")', @entity)
      @correct = @dc.get_attribute_value(@entity, 'y') 
      prepare_result 
      assert_equal(@correct, @returned, "the expected result: #{@correct} does
                   not match the returned result #{@returned}")

      @returned, @markup = @dc.parse_formula('current("z")', @entity)
      @correct = @dc.get_attribute_value(@entity, 'z') 
      prepare_result 
      assert_equal(@correct, @returned, "the expected result: #{@correct} does
                   not match the returned result #{@returned}")

      @returned, @markup = @dc.parse_formula('nearest(300, 203.0, 750.0,
                                                      -100)', @entity)
      @correct =  203.0
      prepare_result 
      assert_equal(@correct, @returned, "the expected result: #{@correct} does
                   not match the returned result #{@returned}")  

      @returned, @markup = @dc.parse_formula('largest(300, 203.0, 750.0,
                                                      -100)', @entity)
      @correct =  750.0
      prepare_result 
      assert_equal(@correct, @returned, "the expected result: #{@correct} does
                   not match the returned result #{@returned}")  

      @returned, @markup = @dc.parse_formula('largest(-300, -203.0, -750.0,
                                                      -100)', @entity)
      @correct =  -100.0
      prepare_result 
      assert_equal(@correct, @returned, "the expected result: #{@correct} does
                   not match the returned result #{@returned}")  

      @returned, @markup = @dc.parse_formula('largest()', @entity)
      @correct = 0.0
      prepare_result 
      assert_equal(@correct, @returned, "the expected result: #{@correct} does
                   not match the returned result #{@returned}")  

      @returned, @markup = @dc.parse_formula('largest(300)', @entity)
      @correct = 300.0 
      prepare_result 
      assert_equal(@correct, @returned, "the expected result: #{@correct} does
                   not match the returned result #{@returned}")  

      @returned, @markup = @dc.parse_formula('smallest(300, 203.0, 750.0, 0.1,
                                                       -0)', @entity)
      @correct = 0.0 
      prepare_result 
      assert_equal(@correct, @returned, "the expected result: #{@correct} does
                   not match the returned result #{@returned}")  

      @returned, @markup = @dc.parse_formula('smallest(-300, -203.0, -750.0,
                                                       -100)', @entity)
      @correct = -750.0
      prepare_result 
      assert_equal(@correct, @returned, "the expected result: #{@correct} does
                   not match the returned result #{@returned}")  

      @returned, @markup = @dc.parse_formula('choose(3, "rosso", "giallo",
                                                     "viola", "blue")',
                                             @entity)
      @correct = "viola" 
      prepare_result 
      assert_equal(@correct, @returned, "the expected result: #{@correct} does
                   not match the returned result #{@returned}")  

      @returned, @markup = @dc.parse_formula('lat()', @entity)
      @correct = 40.017 
      prepare_result 
      assert_equal(@correct, @returned, "the expected result: #{@correct} does
                   not match the returned result #{@returned}")  

      @returned, @markup = @dc.parse_formula('lng()', @entity)
      @correct = -105.283
      prepare_result 
      assert_equal(@correct, @returned, "the expected result: #{@correct} does
                   not match the returned result #{@returned}")  

      @returned, @markup = @dc.parse_formula('faces()', @entity)
      @correct = 16.0 
      prepare_result 
      assert_equal(@correct, @returned, "the expected result: #{@correct} does
                   not match the returned result #{@returned}")  

      @returned, @markup = @dc.parse_formula('edges()', @entity)
      @correct = 42.0
      prepare_result 
      assert_equal(@correct, @returned, "the expected result: #{@correct} does
                   not match the returned result #{@returned}")  

      @returned, @markup = @dc.parse_formula('facearea()', @entity)
      @correct = 119293.280648415
      prepare_result 
      assert_equal(@correct, @returned, "the expected result: #{@correct} does
                   not match the returned result #{@returned}")  

      @returned, @markup = @dc.parse_formula('facearea(
                                             "stone_flagstone_ashlar")',
                                             @entity)
      @correct = 0.0
      prepare_result 
      assert_equal(@correct, @returned, "the expected result: #{@correct} does
                   not match the returned result #{@returned}")  

      @returned, @markup = @dc.parse_formula('facearea("none")', @entity)
      @correct = 109862.155648415 
      prepare_result 
      assert_equal(@correct, @returned, "the expected result: #{@correct} does
                   not match the returned result #{@returned}")  

      @returned, @markup = @dc.parse_formula('facearea("tile_navy")', @entity)
      @correct = 9431.12499999999 
      prepare_result 
      assert_equal(@correct, @returned, "the expected result: #{@correct} does
                   not match the returned result #{@returned}")  

      @returned, @markup = @dc.parse_formula('facearea("tile_navy")', @entity)
      @correct = 9431.12499999999
      prepare_result 
      assert_equal(@correct, @returned, "the expected result: #{@correct} does
                   not match the returned result #{@returned}")  

      @returned, @markup = @dc.parse_formula('facearea("not_in_model")',
                                             @entity)
      @correct = 0.0
      prepare_result 
      assert_equal(@correct, @returned, "the expected result: #{@correct} does
                   not match the returned result #{@returned}")  

      @returned, @markup = @dc.parse_formula('sunelevation()', @entity)
      @correct = 28.2278782222131
      prepare_result 
      assert_equal(@correct, @returned, "the expected result: #{@correct} does
                   not match the returned result #{@returned}")  

      @returned, @markup = @dc.parse_formula('sunangle()', @entity)
      @correct = 208.752792770373 
      prepare_result 
      assert_equal(@correct, @returned, "the expected result: #{@correct} does
                   not match the returned result #{@returned}")  

      @returned, @markup = @dc.parse_formula('optionindex("option name which
                                             does not match")', @entity)
      @correct = -1.0
      prepare_result 
      assert_equal(@correct, @returned, "the expected result: #{@correct} does
                   not match the returned result #{@returned}")

      @returned, @markup = @dc.parse_formula('optionindex("finish")', @entity)
      @correct = 2.0 
      prepare_result 
      assert_equal(@correct, @returned, "the expected result: #{@correct} does
                   not match the returned result #{@returned}")

      @returned, @markup = @dc.parse_formula('optionlabel("finish")', @entity)
      @correct = "low quality"
      prepare_result 
      assert_equal(@correct, @returned, "the expected result: #{@correct} does
                   not match the returned result #{@returned}")

      @returned, @markup = @dc.parse_formula('optionlabel("option name which
                                             does not match")', @entity)
      @correct = nil
      prepare_result 
      assert_equal(@correct, @returned, "the expected result: #{@correct} does
                   not match the returned result #{@returned}")

  end

  # This function runs test for the logical functions 
  #
  # In order to add a test you can use the following template
  #   ------------------------------------------------------ 
  #   @returned, @markup = @dc.parse_formula('<FORMULA TO BE PARSED>', @entity)
  #   @correct = <RESULT/MARKUP YOU EXPECT>
  #   prepare_result #this step is used to avoid computer arithmetic errors 
  #   assert_equal(@correct, @returned, "The expected result: #{@correct} does
  #                not match the returned result #{@returned}")
  #   assert_equal(@correct, @markup, "The expected result: #{@correct} does
  #                not match the returned markup #{@markup}")
  #   ------------------------------------------------------
  #
  # Args:
  #   None
  # Returns:
  #   None
  def test_logical_functions

    @returned, @markup = @dc.parse_formula('and(14444444, 1.0, 3, 4.75, 3, 4,
                                           5, 1, 2, 3444444444, 4, 5, 6, 7,
                                           8, 6, 5, 3, 2, 1333333, 1, 2, 3,
                                           4, 5, 6, 7, 8, 9, 1122220, )',
                                           @entity)
    @correct = @@DC_TRUE
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('and(1, 1.0, 3, 4.75, 3, 4, 5, 1,
                                           2, 3, 4, 5, 6, 7, 8, 6, 5, 3, 2, 1,
                                           1, 2, 3, 4, 5, 6, 7, 8, 9, 0)',
                                           @entity)
    @correct = @@DC_FALSE
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('and(3)', @entity)
    @correct = @@DC_TRUE
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('and(1, 1.0, 3, 4.75)', @entity)
    @correct = @@DC_TRUE
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('and(1, 1.0, 0.3, 4.75)', @entity)
    @correct = @@DC_TRUE
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('and(1, 1.0, -3, 4.75)', @entity)
    @correct = @@DC_TRUE
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('and(0.000001, 4, 1.0, 3, 4.75)',
                                           @entity)
    @correct = @@DC_TRUE
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('and(1, 1.0, 3, 0.0)', @entity)
    @correct = @@DC_FALSE
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('and(1, 1.0, 3, 0)', @entity)
    @correct = @@DC_FALSE
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('true()', @entity)
    @correct = @@DC_TRUE
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
                 
    @returned, @markup = @dc.parse_formula('false()', @entity)
    @correct = @@DC_FALSE
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
  
    @returned, @markup = @dc.parse_formula('if(7=7, 535, 300)', @entity)
    @correct = 535.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
  
    @returned, @markup = @dc.parse_formula('if(-1 = -1, -1, 3)', @entity)
    @correct = -1.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('if(1 = -1, -3, 3)', @entity)
    @correct = 3.0 
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('if("Simone" = "Simone", -1, 3)',
                                           @entity)
    @correct = -1.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('if(7<=7, -535.2, 300.3)', @entity)
    @correct = -535.2
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('if(7<7, -535.2, -300.3)', @entity)
    @correct = -300.3
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('if(7>-7, -535.2, 300.3)', @entity)
    @correct = -535.2
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('if(-1>=-1.000001, -535.2, 300.3)',
                                           @entity)
    @correct = -535.2
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('if(not(1.0), "Simone",
                                           "Jennifer")', @entity)
    @correct = "Jennifer"
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('if(not(and(and(1324, -3.4, true(),
                                           42.5, -2),or(1, -3, 0, false(),
                                           75.3))), "Jennifer", "Simone")',
                                           @entity)
    @correct = "Simone"
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('if(or(not(and(1324,0, -3.4, 12,
                                           42.5, -2)),or(1, -3, 0, 75.3)),
                                           "Jennifer", "Simone")', @entity)
    @correct = "Jennifer"
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('if(or(iseven(3),iseven(2),
                                           isodd(5), false()), -1, -7)',
                                           @entity)
    @correct = -1.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('if(and(not(iseven(6)),true(),
                                           true(), 2), 300.1, -0.3)', @entity)
    @correct = -0.3
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('not(false())', @entity)
    @correct = @@DC_TRUE
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('not(true())', @entity)
    @correct = @@DC_FALSE
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('not(1.0)', @entity)
    @correct = @@DC_FALSE
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('not(0.0)', @entity)
    @correct = @@DC_TRUE
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('not(1)', @entity)
    @correct = @@DC_FALSE
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('not(0)', @entity)
    @correct = @@DC_TRUE 
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('not(0.0000000000001)', @entity)
    @correct = @@DC_FALSE
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('not(-0.0000000000001)', @entity)
    @correct = @@DC_FALSE
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('not(-0.0000000000001)', @entity)
    @correct = @@DC_FALSE
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('not(0.0000000000001)', @entity)
    @correct = @@DC_FALSE
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('not(-1)', @entity)
    @correct = @@DC_FALSE
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('not(-0)', @entity)
    @correct = @@DC_TRUE
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('and(1324, -3.4, true(), 42.5,
                                           -2)', @entity)
    @correct = @@DC_TRUE
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")


    @returned, @markup = @dc.parse_formula('or(1, -3, 0, false() 75.3)',
                                           @entity)
    @correct = @@DC_TRUE
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")


    @returned, @markup = @dc.parse_formula('and(and(1324, -3.4, true(), 42.5,
                                           -2),or(1, -3, 0,false(), 75.3))',
                                           @entity)
    @correct = @@DC_TRUE
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")


    @returned, @markup = @dc.parse_formula('not(and(and(1324, -3.4, true(),
                                           42.5, -2),or(1, -3, 0,false(),
                                           75.3)))', @entity)
    @correct = @@DC_FALSE
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")


    @returned, @markup = @dc.parse_formula('or(or(false(), and(true())))',
                                           @entity)
    @correct = @@DC_TRUE
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

  end        
          
  # This function runs test for the math functions 
  #
  # In order to add a test you can use the following template
  #   ------------------------------------------------------ 
  #   @returned, @markup = @dc.parse_formula('<FORMULA TO BE PARSED>', @entity)
  #   @correct = <PUT HERE THE RESULT/MARKUP YOU EXPECT>
  #   prepare_result #this step is used to avoid computer arithmetic errors 
  #   assert_equal(@correct, @returned, "The expected result: #{@correct} does
  #                not match the returned result #{@returned}")
  #   assert_equal(@correct, @markup, "The expected result: #{@correct} does
  #                not match the returned markup #{@markup}")
  #   ------------------------------------------------------
  #
  # Args:
  #   None
  # Returns:
  #   None
  def test_math_functions
    
    @returned, @markup = @dc.parse_formula('abs(0)', @entity)
    @correct = 0.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('abs(1)', @entity)
    @correct = 1.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('abs(-546.2)', @entity)
    @correct = 546.2
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('abs(-0.0)', @entity)
    @correct = 0.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
  
    @returned, @markup = @dc.parse_formula('abs(round(-24.500001))', @entity)
    @correct = 25.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned, @markup = @dc.parse_formula('abs(floor(-24.999999))', @entity)
    @correct = 25.0 
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('abs(ceiling(-24.000001))', @entity)
    @correct = 25.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('acos(0)', @entity)
    @correct = 90.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('acos(1)', @entity)
    @correct = 0.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('acos(cos(30))', @entity)
    @correct = 30.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('asin(0)', @entity)
    @correct =0.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('asin(1)', @entity)
    @correct = 90.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
                 
    @returned, @markup = @dc.parse_formula('asin(sin(55))', @entity)
    @correct = 55.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    #Various Trigonometric Identities
    x = (Kernel::rand())*90
    @returned, @markup = @dc.parse_formula('atan(tan(' + x.to_s + '))',
                                           @entity)
    @correct = x.to_f
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('asin(sin(' + x.to_s + '))',
                                           @entity)
    @correct = x.to_f
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('acos(cos(' + x.to_s + '))',
                                           @entity)
    @correct = x.to_f 
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    #sqrt(sin(x)^2 + cos(x)^2) = 1 #below
    x = (Kernel::rand())*360
    @returned, @markup = @dc.parse_formula('sqrt(sin(' + x.to_s + ') *
                                           sin(' + x.to_s + ') + cos(' +
                                           x.to_s + ') * cos(' + x.to_s +
                                           '))', @entity)
    @correct = 1.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('cos(' + x.to_s + ') - (sin(90 -' +
                                           x.to_s + '))', @entity)
    @correct = 0.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('sin(' + x.to_s + ') - (cos(90 -' +
                                           x.to_s + '))', @entity)
    @correct = 0.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('atanh(tanh(' + x.to_s + '))',
                                           @entity)
    @correct = x.to_f
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('asinh(sinh(' + x.to_s + '))',
                                           @entity)
    @correct = x.to_f
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned, @markup = @dc.parse_formula('acosh(cosh(' + x.to_s + '))',
                                           @entity)
    @correct = x.to_f
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
  
    #tan(x) = sin(x)/cos(x) below         
    @returned, @markup = @dc.parse_formula('(tan(' + x.to_s + ')) - ((sin(' +
                                           x.to_s + '))/(cos(' + x.to_s +
                                           ')))', @entity)
    @correct = 0.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('(tan(30)) - ((sin(30))/(cos(30)))',
                                           @entity)
    @correct = 0.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    #tanh(x) = sinh(x)/cosh(x) below             
    @returned, @markup = @dc.parse_formula('(tanh(' + x.to_s + ')) - ((sinh(' +
                                           x.to_s + '))/(cosh(' + x.to_s +
                                           ')))', @entity)
    @correct = 0.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('(tanh(30)) -
                                           ((sinh(30))/(cosh(30)))', @entity)
    @correct = 0.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
 
    #cosh(-x) =  cosh(x)
    @returned, @markup = @dc.parse_formula('cosh(-' + x.to_s + ') - cosh(' +
                                           x.to_s + ')', @entity)
    @correct = 0.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    #sinh(-x) = -sinh(x)
    @returned, @markup = @dc.parse_formula('sinh(-' + x.to_s + ') + sinh(' +
                                           x.to_s + ')', @entity)
    @correct = 0.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
  
    #tanh(-x) = -tanh(x)
    @returned, @markup = @dc.parse_formula('tanh(-' + x.to_s + ') + tanh(' +
                                           x.to_s + ')', @entity)
    @correct = 0.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    y = (Kernel::rand())*360
    #sin(x) + sin(y) = 2 * sin((x+y)/2) * cos((x-y)/2) below 
    @returned, @markup = @dc.parse_formula('(sin(' + x.to_s + ') + sin(' +
                                           y.to_s + ')) - ( 2 * (sin((' +
                                           x.to_s + '+' + y.to_s + ')/2))
                                           * (cos((' + x.to_s + '-' + y.to_s +
                                           ')/2)))', @entity)
    @correct = 0.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('(sin(30) + sin(45)) - (2*
                                           (sin((30+45)/2))*(cos((30-45)/2)))',
                                           @entity)
    @correct = 0.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('ceiling(-32.0000000001)', @entity)
    @correct = -33.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('ceiling(32.0000000001)', @entity)
    @correct = 33.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('ceiling(35.999999999)', @entity)
    @correct = 36.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('ceiling(-35.999999999)', @entity)
    @correct = -36.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('cos(0)', @entity)
    @correct = 1.0    
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
                 
    @returned, @markup = @dc.parse_formula('cos(45)', @entity)
    @correct = 0.707106781186548
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('cos(90)', @entity)
    @correct = 0.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('cos(120)', @entity)
    @correct = -0.5
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('cos(180)', @entity)
    @correct = -1.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
  
    @returned, @markup = @dc.parse_formula('cos(270)', @entity)
    @correct = 0.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('cos(240)', @entity)
    @correct = -0.5
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('cos(360)', @entity)
    @correct = 1.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('cos(-360)', @entity)
    @correct = 1.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('cos(-90)', @entity)
    @correct = 0.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('cos(-180)', @entity)
    @correct = -1.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('cos(720)', @entity)
    @correct = 1.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('cos(-720)', @entity)
    @correct = 1.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('sin(0)', @entity)
    @correct = 0.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
                 
    @returned, @markup = @dc.parse_formula('sin(45)', @entity)
    @correct = 0.707106781186548
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('sin(90)', @entity)
    @correct = 1.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('sin(120)', @entity)
    @correct = 0.866025403784439
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('sin(180)', @entity)
    @correct = 0.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
  
    @returned, @markup = @dc.parse_formula('sin(270)', @entity)
    @correct = -1.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('sin(240)', @entity)
    @correct = -0.866025403784438
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('sin(360)', @entity)
    @correct = 0.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('sin(-360)', @entity)
    @correct = 0.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('sin(-90)', @entity)
    @correct = -1.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('sin(-180)', @entity)
    @correct = 0.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('sin(720)', @entity)
    @correct = 0.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('sin(-720)', @entity)
    @correct = 0.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('degrees(pi())', @entity)
    @correct = 180.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('degrees(3.14159265358979)',
                                           @entity)
    @correct = 180.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('degrees(1)', @entity)
    @correct = 57.2957795130823
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('even(3.00000000001)', @entity)
    @correct =  4.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('even(2.00000000001)', @entity)
    @correct = 4.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
  
    @returned, @markup = @dc.parse_formula('even(-3.00000000001)', @entity)
    @correct = -2.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('even(-3.99999999999)', @entity)
    @correct = -2.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
                 
    @returned, @markup = @dc.parse_formula('exp(0)', @entity)
    @correct = 1.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
  
    @returned, @markup = @dc.parse_formula('exp(-0)', @entity)
    @correct = 1.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
  
    @returned, @markup = @dc.parse_formula('exp(1)', @entity)
    @correct = 2.71828182845905
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('exp(-1)', @entity)
    @correct = 1/2.71828182845905
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

#TODO(snicolo): When the Factorial function(fact()) is implemented this tests
#               can be uncommented.

#    @returned, @markup = @dc.parse_formula('fact(0)', @entity)
#    @correct = 1.0
#    prepare_result 
#    assert_equal(@correct, @returned, "the expected result: #{@correct} does
#                 not match the returned result #{@returned}")

#    @returned, @markup = @dc.parse_formula('fact(-0)', @entity)
#    @correct = 1.0
#    prepare_result 
#    assert_equal(@correct, @returned, "the expected result: #{@correct} does
#                 not match the returned result #{@returned}")

#    @returned, @markup = @dc.parse_formula('fact(-1)', @entity)
#    @correct = 1.0
#    prepare_result 
#    assert_equal(@correct, @returned, "the expected result: #{@correct} does
#                 not match the returned result #{@returned}")

#    @returned, @markup = @dc.parse_formula('fact(2)', @entity)
#    @correct = 2.0
#    prepare_result 
#    assert_equal(@correct, @returned, "the expected result: #{@correct} does
#                 not match the returned result #{@returned}")

#    @returned, @markup = @dc.parse_formula('fact(3)', @entity)
#    @correct = 6.0 
#    prepare_result 
#    assert_equal(@correct, @returned, "the expected result: #{@correct} does
#                 not match the returned result #{@returned}")

#    @returned, @markup = @dc.parse_formula('fact(4)', @entity)
#    @correct = 24.0
#    prepare_result 
#    assert_equal(@correct, @returned, "the expected result: #{@correct} does
#                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('floor(79.0000000001)', @entity)
    @correct = 79.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('floor(-79.0000000001)', @entity)
    @correct = -80.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('floor(33.9999999999)', @entity)
    @correct = 33.0    
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('floor(-33.9999999999)', @entity)
    @correct = -34.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('int(0.0000)', @entity)
    @correct = 0.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned, @markup = @dc.parse_formula('int(10.0000000000001)', @entity)
    @correct = 10.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('int(10.9999999999999)', @entity)
    @correct = 10.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('int(-1.0000000000001)', @entity)
    @correct = -2.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('int(-2.9999999999999)', @entity)
    @correct = -3.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
             
    @returned, @markup = @dc.parse_formula('iseven(8.43287998078900098434511' +
                                           '6789976542217657343425656)',
                                           @entity)
    @correct = @@DC_TRUE
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('iseven(8)', @entity)
    @correct = @@DC_TRUE
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned, @markup = @dc.parse_formula('iseven(-8)', @entity)
    @correct = @@DC_TRUE
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('iseven(-8.000000000000000001)',
                                           @entity)
    @correct = @@DC_TRUE
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned, @markup = @dc.parse_formula('iseven(-8.999999999999)', @entity)
    @correct = @@DC_TRUE
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned, @markup = @dc.parse_formula('iseven(7.4328799807890009843451' +
                                           '6789976542217657343425656)',
                                           @entity)
    @correct = @@DC_FALSE
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned, @markup = @dc.parse_formula('iseven(7.000000001)', @entity)
    @correct = @@DC_FALSE
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned, @markup = @dc.parse_formula('iseven(-7)', @entity)
    @correct = @@DC_FALSE
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned, @markup = @dc.parse_formula('iseven(-7.999999999999)', @entity)
    @correct = @@DC_FALSE
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned, @markup = @dc.parse_formula('isodd(8.432879980789000984345116
                                           789976542217657343425656)', @entity)
    @correct = @@DC_FALSE
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('isodd(8)', @entity)
    @correct = @@DC_FALSE
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned, @markup = @dc.parse_formula('isodd(-8)', @entity)
    @correct = @@DC_FALSE
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned, @markup = @dc.parse_formula('isodd(-8.000000000000000001)',
                                           @entity)
    @correct = @@DC_FALSE
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('isodd(-8.999999999999)', @entity)
    @correct = @@DC_FALSE
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('isodd(7.432879980789000984345116' +
                                                  '789976542217657343425656)',
                                           @entity)
    @correct = @@DC_TRUE
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('isodd(7.0000000001)', @entity)
    @correct = @@DC_TRUE
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('isodd(-7)', @entity)
    @correct = @@DC_TRUE
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
                 
    @returned, @markup = @dc.parse_formula('isodd(-7.999999999999)', @entity)
    @correct = @@DC_TRUE 
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('ln(1)', @entity)
    @correct = 0.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('ln(2.71828182845904523536028)',
                                           @entity)
    @correct = 1.0
    prepare_result
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('ln(1/2.71828182845904523536028)',
                                           @entity)
    @correct = -1.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('ln((2.71828182845904523536028 *
                                           2.71828182845904523536028))',
                                           @entity)
    @correct = 2.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

#TODO(snicolo): When the markup code has been refactored this tests need to 
#               be uncommented and fixed
#    @returned, @markup = @dc.parse_formula('ln(0)', @entity)
#    @correct = "MINUS INFINITY"
#    prepare_result 
#    assert_equal(@correct, @returned, "the expected result: #{@correct} does
#                not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('log10(1)', @entity)
    @correct = 0.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('log10(10)', @entity)
    @correct = 1
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('log10(0.1)', @entity)
    @correct = -1.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('log10(1000)', @entity)
    @correct = 3.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

#TODO(snicolo): When the markup code has been refactored this tests need to 
#               be uncommented and fixed
#    @returned, @markup = @dc.parse_formula('log10(0)', @entity)
#    @correct = "MINUS INFINITY"
#    prepare_result 
#    assert_equal(@correct, @returned, "the expected result: #{@correct} does
#                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('odd(3.00000000001)', @entity)
    @correct = 5.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('odd(2.00000000001)', @entity)
    @correct = 3.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('odd(-3.00000000001)', @entity)
    @correct = -3.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('odd(-4.99999999999)', @entity)
    @correct = -3.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('pi()', @entity)
    @correct = Math::PI
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    # Test new POWER() function added in SU 8.0
    @returned, @markup = @dc.parse_formula('power(2,2)', @entity)
    @correct = 4.0
    prepare_result
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('power(2,3)', @entity)
    @correct = 8.0
    prepare_result
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('power("200",3.3)', @entity)
    @correct = 39210193.5151592
    prepare_result
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('power(-123,-3.3)', @entity)
    @correct = -1.26856618973818e-007
    prepare_result
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('power(42,0)', @entity)
    @correct = 1.0
    prepare_result
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('power(0,1237)', @entity)
    @correct = 0.0
    prepare_result
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('radians(degrees(pi()))', @entity)
    @correct = Math::PI
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('if(and(rand()<=1, rand()>=0),
                                           "Rand Works", "Rand is Broken")',
                                           @entity)
    @correct = "Rand Works"
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('round(-24.500001)', @entity)
    @correct = -25.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('round(-24.499999)', @entity)
    @correct = -24.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('round(42.000000000000000001)',
                                           @entity)
    @correct = 42.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('round(42.999999999999999)',
                                           @entity)
    @correct = 43.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('round(24.499999)', @entity)
    @correct = 24.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('round(24.5000001)', @entity)
    @correct = 25.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('sign(0)', @entity)
    @correct = 0.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('sign(-0)', @entity)
    @correct = 0.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('sign(-3432)', @entity)
    @correct = -1.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('sign(+3232)', @entity)
    @correct = 1.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('sign(777)', @entity)
    @correct = 1.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('sqrt(0)', @entity)
    @correct = 0.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

#TODO(snicolo): When the markup code has been refactored this tests need to 
#               be uncommented and fixed
#    @returned, @markup = @dc.parse_formula('sqrt(-1)', @entity)
#    @correct = "INVALID ARGUMENT"
#    prepare_result 
#    assert_equal(@correct, @returned, "the expected result: #{@correct} does
#                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('sqrt(1)', @entity)
    @correct = 1.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('sqrt(4)', @entity)
    @correct = 2.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('sqrt(16)', @entity)
    @correct = 4.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('sqrt(65466.4343)', @entity)
    @correct = 255.864093416798
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('tan(0)', @entity)
    @correct = 0.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('tan(45)', @entity)
    @correct = 1.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('tan(-45)', @entity)
    @correct = -1.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

#TODO(snicolo): When the markup code has been refactored this tests need to 
#               be uncommented and fixed
#    @returned, @markup = @dc.parse_formula('tan(90)', @entity)
#    @correct = "INFINITY"
#    prepare_result 
#    assert_equal(@correct, @returned, "the expected result: #{@correct} does
#                 not match the returned result #{@returned}")

  end        
          
          
  # This function runs test for the parenthesis nesting 
  #
  # In order to add a test you can use the following template
  #   ------------------------------------------------------ 
  #   @returned, @markup = @dc.parse_formula('<FORMULA TO BE PARSED>', @entity)
  #   @correct = <RESULT/MARKUP YOU EXPECT>
  #   prepare_result #this step is used to avoid computer arithmetic errors 
  #   assert_equal(@correct, @returned, "The expected result: #{@correct} does
  #                not match the returned result #{@returned}")
  #   assert_equal(@correct, @markup, "The expected result: #{@correct} does
  #                not match the returned markup #{@markup}")
  #   ------------------------------------------------------
  #
  # Args:
  #   None
  # Returns:
  #   None
  def test_parens
    
    @returned, @markup = @dc.parse_formula('12/(6+6)', @entity)
    @correct = 1.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('12/6+6', @entity)
    @correct = 8.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('12/((6+6))', @entity)
    @correct = 1.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
                 
    @returned, @markup = @dc.parse_formula('12/(round(6+6))', @entity)
    @correct = 1.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('12/(1*(6+6))', @entity)
    @correct = 1.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('12/(1*(6+6)*1*(1))', @entity)
    @correct = 1.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('12/(1*(6+6)*2*(1))', @entity)
    @correct = 0.5
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('(12)/(1*(6+6)*1*(1))', @entity)
    @correct = 1.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('(12)/(1*6+6*1*(1))', @entity)
    @correct = 1.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('(12/(6+6))', @entity)
    @correct = 1.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned, @markup = @dc.parse_formula('(12/6+6)', @entity)
    @correct = 8.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
                 
    @returned, @markup = @dc.parse_formula('(12/((6+6)))', @entity)
    @correct = 1.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('(12/(round(6+6)))', @entity)
    @correct = 1.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('(12/(1*(6+6)))', @entity)
    @correct = 1.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('(12/(1*(6+6)*1*(1)))', @entity)
    @correct = 1.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('((12)/(1*(6+6)*1*(1)))', @entity)
    @correct = 1.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('((12)/(1*6+6*1*(1)))', @entity)
    @correct = 1.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('( ( ( ( ((((1) ) ))))))', @entity)
    @correct = 1.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    @returned, @markup = @dc.parse_formula('( ( ( ( (((floor(1.1) ) ))))))',
                                           @entity)
    @correct = 1.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('( ( ( ( ((-(floor(1.1) ) ))))))',
                                           @entity)
    @correct = -1.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('( ( ( ( (((floor(1.1,1) ) ))))))',
                                           @entity)
    @correct = 1.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('(floor(5,2))', @entity)
    @correct = 4.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('1-(1+floor(5,2))', @entity)
    @correct = -4.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('floor(5,2)', @entity)
    @correct = 4.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('if(((and(rand()<=1, rand()>=0),
                                              "Rand Works", "Rand is Broken")',
                                           @entity)
    @correct = "<span class=subformula-error>PARENS COUNT</span> " 
    prepare_result
    assert_equal(@correct, @markup, "the expected result: #{@correct} does
                 not match the returned markup #{@markup}")
    
    @returned, @markup = @dc.parse_formula('if(finish>0,finish,0)-
                                           if(finish>0,1,0)', @entity)
    @correct = 49.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('10*-1', @entity)
    @correct = -10.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('10*(-1)', @entity)
    @correct = -10.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('(10)*(-1)', @entity)
    @correct = -10.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('(10*-1)', @entity)
    @correct = -10.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('(-10*1)', @entity)
    @correct = -10.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('-10*1', @entity)
    @correct = -10.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned, @markup = @dc.parse_formula('-(-10*1)', @entity)
    @correct = 10.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('-(10*1)', @entity)
    @correct = -10.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
  end

  # This function runs test for the text functions 
  #
  # In order to add a test you can use the following template
  #   ------------------------------------------------------ 
  #   @returned, @markup = @dc.parse_formula('<FORMULA TO BE PARSED>', @entity)
  #   @correct = <RESULT/MARKUP YOU EXPECT>
  #   prepare_result #this step is used to avoid computer arithmetic errors 
  #   assert_equal(@correct, @returned, "The expected result: #{@correct} does
  #                not match the returned result #{@returned}")
  #   assert_equal(@correct, @markup, "The expected result: #{@correct} does
  #                not match the returned markup #{@markup}")
  #   ------------------------------------------------------
  #
  # Args:
  #   None
  # Returns:
  #   None
  def test_text_functions
    
    for i in (1..255) 
      @returned, @markup = @dc.parse_formula('char(' + i.to_s + ')', @entity)
      @correct = i.chr
      prepare_result 
      assert_equal(@correct, @returned, "the expected result: #{@correct} does
                   not match the returned result #{@returned}")      
    end

    @returned, @markup = @dc.parse_formula('code("SIMONENICOLO")', @entity)
    @correct = 83.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned, @markup = @dc.parse_formula('code("%4jenniferBeltzer")',
                                           @entity)
    @correct =  37.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('code("\"")', @entity)
    @correct = 34.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('code(6.0)', @entity)
    @correct = 54.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('code((2+2))', @entity)
    @correct = 52.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('code("(")', @entity)
    @correct = 40.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('code(" ")', @entity)
    @correct = 32.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('code("#")', @entity)
    @correct = 35.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('concatenate("simone", "jennifer",
                                                        "luigi", "maria",
                                                        "christian")', @entity)
    @correct = "simonejenniferluigimariachristian"
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned, @markup = @dc.parse_formula('concatenate("simone", "+",
                                                        "jennifer", "(",
                                                        "luigi)", "maria",
                                                        "#christian")',
                                           @entity)
    @correct = "simone+jennifer(luigi)maria#christian"
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned, @markup = @dc.parse_formula('concatenate("simone", "-",
                                                        "jennifer", "test",
                                                        "-34", "maria",
                                                        "#christian")',
                                           @entity)
    @correct = "simone-jennifertest-34maria#christian"
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned, @markup = @dc.parse_formula('concatenate("1","+34","maria")',
                                           @entity)
    @correct = "1+34maria"
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned, @markup = @dc.parse_formula('concatenate("Simone", " ",
                                                        "Giulia","1201",
                                                        "Ciao")', @entity)
    @correct = "Simone Giulia1201Ciao"
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    
    @returned, @markup = @dc.parse_formula('dollar(300)', @entity)
    @correct = "$300.00" 
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
        
    @returned, @markup = @dc.parse_formula('dollar(3540)', @entity)
    @correct = "$3,540.00"
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
     
    @returned, @markup = @dc.parse_formula('dollar(3540.765)', @entity)
    @correct = "$3,540.76"
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('dollar(3540 + 1.25 - 7.01)', 
                                           @entity)
    @correct = "$3,534.24"
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
     
    @returned, @markup = @dc.parse_formula('dollar(250 + 300 / 2)', @entity)
    @correct = "$400.00"
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned, @markup = @dc.parse_formula('dollar(250.9999)', @entity)
    @correct = "$251.00"
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
     
    @returned, @markup = @dc.parse_formula('exact("Simone","simone")', @entity)
    @correct = @@DC_FALSE
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned, @markup = @dc.parse_formula('exact("simone","simone")', @entity)
    @correct = @@DC_TRUE
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
     
    @returned, @markup = @dc.parse_formula('exact(")",")")', @entity)
    @correct = @@DC_TRUE
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned, @markup = @dc.parse_formula('exact("SiMonE#$/3r",
                                           "SiMonE#$/3r")', @entity)
    @correct = @@DC_TRUE
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
     
    @returned, @markup = @dc.parse_formula('exact(code("Standard"), 
                                           code("Supreme"))', @entity)
    @correct = @@DC_TRUE
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned, @markup = @dc.parse_formula('exact(code(and(sin(30), true())),
                                           code(1.0))', @entity)
    @correct = 1.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('exact(if(false(), "simone",
                                                     "jennifer"), if(true(),
                                                     "jennifer", "simone"))',
                                           @entity)
    @correct = @@DC_TRUE
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned, @markup = @dc.parse_formula('find("o","Simone Rosario Piero 
                                           Nicolo")', @entity)
    @correct = 4.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
     
    @returned, @markup = @dc.parse_formula('find("!",
                                           "Sm#$one $osario Mi$ero Ni$c#o@l!o",
                                                 1 )', @entity)
    @correct = 32.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
     
    @returned, @markup = @dc.parse_formula('find("o","Simone Rosario Piero 
                                           Nicolo", 1)', @entity)
    @correct = 4.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned, @markup = @dc.parse_formula('find("o","Simone Rosario Piero
                                           Nicolo", 4)', @entity)
    @correct = 4.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
     
    @returned, @markup = @dc.parse_formula('find("o","Simone Rosario Piero
                                           Nicolo", 5)', @entity)
    @correct = 9.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('find("1","1Simone 123Rosario4321
                                           Pier1o Nic1olo", 3)', @entity)
    @correct = 9.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('left("Simone", 0)', @entity)
    @correct = ""
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
     
    @returned, @markup = @dc.parse_formula('left("Simone")', @entity)
    @correct = "S"
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned, @markup = @dc.parse_formula('left("Simone", 1)', @entity)
    @correct = "S"
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
     
    @returned, @markup = @dc.parse_formula('left("Simone", 3)', @entity)
    @correct = "Sim"
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

#TODO(snicolo): When the markup code has been refactored this tests need to 
#               be uncommented and fixed
#    @returned, @markup = @dc.parse_formula('left("Simone", -1)', @entity)
#    @correct = "NEGATIVE ARGUMENT"
#    prepare_result
#    assert_equal(@correct, @returned, "the expected result: #{@correct} does
#                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('left(concatenate("Simone",
                                                             "Giulia"), 12)',
                                           @entity)
    @correct = "SimoneGiulia"
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
     
    @returned, @markup = @dc.parse_formula('left(concatenate("Simone",
                                                             "Giulia"), 11)',
                                           @entity)
    @correct = "SimoneGiuli"
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('left(concatenate("Simone",
                                                             "Giulia"), 13)',
                                           @entity)
    @correct = "SimoneGiulia"
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('left(concatenate("Simone",
                                                             "Giulia"),
                                                 133)', @entity)
    @correct = "SimoneGiulia"
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('left("!Simone")', @entity)
    @correct = "!"
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned, @markup = @dc.parse_formula('left("<()!@#(Simone ")', @entity)
    @correct = "<"
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
     
    @returned, @markup = @dc.parse_formula('left("1<()!@#(Simone ", 10)',
                                           @entity)
    @correct = "1<()!@#(Si"
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('len(" Simone ")', @entity)
    @correct = 8.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
     
    @returned, @markup = @dc.parse_formula('len("Simone")', @entity)
    @correct = 6.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned, @markup = @dc.parse_formula('len(proper(concatenate("1231",
                                                                   " Simone",
                                                                   " ",
                                                                   "Bello")))',
                                           @entity)
    @correct = 17.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
     
    @returned, @markup = @dc.parse_formula('len("")', @entity)
    @correct = 0.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned, @markup = @dc.parse_formula('len(" ")', @entity)
    @correct = 1.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
     
    @returned, @markup = @dc.parse_formula('len("123.0001")', @entity)
    @correct = 8.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('lower("")', @entity)
    @correct = ""
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
     
    @returned, @markup = @dc.parse_formula('lower("-1234")', @entity)
    @correct = "-1234"
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned, @markup = @dc.parse_formula('lower("W")', @entity)
    @correct = "w"
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
     
    @returned, @markup = @dc.parse_formula('lower("y")', @entity)
    @correct = "y"
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned, @markup = @dc.parse_formula('lower("25*Scott")', @entity)
    @correct = "25*scott"
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
     
    @returned, @markup = @dc.parse_formula('lower("25*"&"Scott")', @entity)
    @correct = "25*scott"
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned, @markup = @dc.parse_formula('lower(345.4)', @entity)
    @correct = "345.4"
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
     
    @returned, @markup = @dc.parse_formula('lower("Y@#$%^&*")', @entity)
    @correct = "y@\#\$%^&*"
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned, @markup = @dc.parse_formula('lower("#$")', @entity)
    @correct = "\#\$"
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('lower(" ")', @entity)
    @correct = " "
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('upper("")', @entity)
    @correct = ""
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('upper("  ")', @entity)
    @correct = "  "
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned, @markup = @dc.parse_formula('upper("-1234")', @entity)
    @correct = "-1234"
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
     
    @returned, @markup = @dc.parse_formula('upper("W")', @entity)
    @correct = "W"
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned, @markup = @dc.parse_formula('upper("y")', @entity)
    @correct = "Y"
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
     
    @returned, @markup = @dc.parse_formula('upper("y@#$%^&*")', @entity)
    @correct = "Y@\#$%^&*"
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned, @markup = @dc.parse_formula('upper(lower("sImOnE"))', @entity)
    @correct = "SIMONE"
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
     
    @returned, @markup = @dc.parse_formula('lower(upper("SiMoNe"))', @entity)
    @correct = "simone"
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned, @markup = @dc.parse_formula('upper(lower("sImOnE"))', @entity)
    @correct = "SIMONE"
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
     
    @returned, @markup = @dc.parse_formula('proper(lower("SIMone123"))',
                                           @entity)
    @correct = "Simone123"
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned, @markup = @dc.parse_formula('proper(upper("simOne123"))',
                                           @entity)
    @correct = "Simone123"
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('mid("Simone&Giulia", 3, 6)',
                                           @entity)
    @correct = "mone&G"
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned, @markup = @dc.parse_formula('mid("Simone&Giulia", 4, 3)',
                                           @entity)
    @correct = "one"
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
     
#TODO(snicolo): When the markup code has been refactored this tests need to 
#               be uncommented and fixed
#    @returned, @markup = @dc.parse_formula('mid("Simone&Giulia", -3, -6)',
                 #    @entity)
#    @correct = "OUT OF RANGE ARGUMENT"
#    prepare_result 
#    assert_equal(@correct, @returned, "the expected result: #{@correct} does
#                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('mid("SimoneGiulia", 3, 6)',
                                           @entity)
    @correct = "moneGi"
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
     
    @returned, @markup = @dc.parse_formula('mid("SimoneGiulia", 4, 3)',
                                           @entity)
    @correct = "one"
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
#TODO(snicolo): When the markup code has been refactored this tests need to 
#               be uncommented and fixed
#    @returned, @markup = @dc.parse_formula('mid("SimoneGiulia", -3, -6)',
#                                           @entity)
#    @correct = "OUT OF RANGE ARGUMENT"
#    prepare_result 
#    assert_equal(@correct, @returned, "the expected result: #{@correct} does
#                 not match the returned result #{@returned}")
     
#TODO(snicolo): When the markup code has been refactored this tests need to 
#               be uncommented and fixed
#    @returned, @markup = @dc.parse_formula('mid("SimoneGiulia", -3, 0)',
#                                           @entity)
#    @correct = "OUT OF RANGE ARGUMENT"
#    prepare_result 
#    assert_equal(@correct, @returned, "the expected result: #{@correct} does
#                 not match the returned result #{@returned}")
    
#TODO(snicolo): When the markup code has been refactored this tests need to 
#               be uncommented and fixed
#    @returned, @markup = @dc.parse_formula('mid("SimoneGiulia", 0, -3)',
#                                           @entity)
#    @correct = "OUT OF RANGE ARGUMENT"
#    prepare_result 
#    assert_equal(@correct, @returned, "the expected result: #{@correct} does
#                 not match the returned result #{@returned}")
     
    @returned, @markup = @dc.parse_formula('mid("Simone Giulia1201Ciao",
                                                10, 13)', @entity)
    @correct = "ulia1201Ciao"
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned, @markup = @dc.parse_formula('mid("SimoneGiulia", 3, 3)',
                                           @entity)
    @correct = "mon"
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
     
    @returned, @markup = @dc.parse_formula('mid("Si moneGiulia", 3, 3)',
                                           @entity)
    @correct = " mo"
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
#TODO(snicolo): When the markup code has been refactored this tests need to 
#               be uncommented and fixed
#    @returned, @markup = @dc.parse_formula('mid("SimoneGiulia")', @entity)
#    @correct = "OUT OF RANGE ARGUMENT"
#    prepare_result 
#    assert_equal(@correct, @returned, "the expected result: #{@correct} does
#                 not match the returned result #{@returned}")
     
    @returned, @markup = @dc.parse_formula('mid(concatenate("Simone", " ",
                                                            "Giulia", "1201",
                                                            "Ciao"), 10, 13)',
                                           @entity)
    @correct = "ulia1201Ciao"
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned, @markup = @dc.parse_formula('replace("SimoneSimoneSimone",
                                           3, 1, "Giulia")', @entity)
    @correct = "SiGiuliaoneSimoneSimone"
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
     
    @returned, @markup = @dc.parse_formula('replace("SimoneSimoneSimone",
                                           6, 12, "GiuliaChiari")', @entity)
    @correct = "SimonGiuliaChiarie"
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned, @markup = @dc.parse_formula('rept("Simone", 4)', @entity)
    @correct = "SimoneSimoneSimoneSimone"
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
     
    @returned, @markup = @dc.parse_formula('rept("Simone", 0)', @entity)
    @correct = ""
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned, @markup = @dc.parse_formula('rept("Simone")', @entity)
    @correct = ""
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
     
    @returned, @markup = @dc.parse_formula('rept("Simone", -2)', @entity)
    @correct = ""
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned, @markup = @dc.parse_formula('right("Simone", 0)', @entity)
    @correct = ""
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
     
    @returned, @markup = @dc.parse_formula('right("Simone")', @entity)
    @correct = "e"
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned, @markup = @dc.parse_formula('right("Simone", 1)', @entity)
    @correct = "e"
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
     
#TODO(snicolo): When the markup code has been refactored this tests need to 
#               be uncommented and fixed
#    @returned, @markup = @dc.parse_formula('right("Simone", -1)', @entity)
#    @correct = "NEGATIVE ARGUMENT"
#    prepare_result 
#    assert_equal(@correct, @returned, "the expected result: #{@correct} does
#                not match the returned result #{@returned}")
    
    @returned, @markup = @dc.parse_formula('right(concatenate("Simone",
                                                              "Giulia"), 12)',
                                           @entity)
    @correct = "SimoneGiulia"
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
     
    @returned, @markup = @dc.parse_formula('right(concatenate("Simone",
                                                              "Giulia"), 11)',
                                           @entity)
    @correct = "imoneGiulia"
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned, @markup = @dc.parse_formula('right(concatenate("Simone",
                                                              "Giulia"), 13)',
                                           @entity)
    @correct = "SimoneGiulia" 
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
     
    @returned, @markup = @dc.parse_formula('right(concatenate("Simone",
                                                              "Giulia"), 120)',
                                           @entity)
    @correct = "SimoneGiulia" 
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned, @markup = @dc.parse_formula('right("Simone!")', @entity)
    @correct = "!"
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
     
    @returned, @markup = @dc.parse_formula('right("<()!@#(Simone =_")',
                                           @entity)
    @correct = "_"
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned, @markup = @dc.parse_formula('right("1<()!@#(Si", 10)', @entity)
    @correct = "1<()!@#(Si"
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned, @markup = @dc.parse_formula('upper("(5,5)")', @entity)
    @correct = "(5,5)"
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned, @markup = @dc.parse_formula('lower("scott!reference")', @entity)
    @correct = "scott!reference"
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned, @markup = @dc.parse_formula('left("scott!reference",5)',
                                           @entity)
    @correct = "scott"
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned, @markup = @dc.parse_formula('right("1<!@#Si", 7)', @entity)
    @correct = "1<!@#Si"
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned, @markup = @dc.parse_formula('search("imo", "SimoneSimone")',
                                           @entity)
    @correct = 2.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned, @markup = @dc.parse_formula('search("imon", "SimoneSimone",1)',
                                           @entity)
    @correct = 2.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
#TODO(snicolo): When the markup code has been refactored this tests need to 
#               be uncommented and fixed
#    @returned, @markup = @dc.parse_formula('search("Distr", "SimoneSimone")', 
#                                           @entity)
#    @correct = "NOT FOUND"
#    prepare_result 
#    assert_equal(@correct, @returned, "the expected result: #{@correct} does
#                 not match the returned result #{@returned}")
    
#TODO(snicolo): When the markup code has been refactored this tests need to 
#               be uncommented and fixed
#    @returned, @markup = @dc.parse_formula('search("Distr", "SimoneSimone",
#                                                   15)',
#                                           @entity)
#    @correct = "NOT FOUND"
#    prepare_result 
#    assert_equal(@correct, @returned, "the expected result: #{@correct} does
#                 not match the returned result #{@returned}")
    
    @returned, @markup = @dc.parse_formula('search("imo", "SimoneSimone", 4)',
                                           @entity)
    @correct = 8.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned, @markup = @dc.parse_formula('search("imo",
                                           "SimoneS!@#$%^&*()_+=-imone",8)',
                                           @entity)
    @correct = 22.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned, @markup = @dc.parse_formula('substitute("Simone gioca A Calcio",
                                                       "gioca", "non gioca",
                                                       1)',
                                           @entity)
    @correct = "Simone non gioca A Calcio"
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned, @markup = @dc.parse_formula('substitute("Simone gioca A Calcio",
                                                     "gioca", "non gioca", 0)',
                                           @entity)
    @correct = "Simone gioca A Calcio"
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned, @markup = @dc.parse_formula('substitute("Simone gioca A Pallone e gli piace moltissimo, gli piace veramente troppo, gli piace playboy", "gli piace", "assolutamente non gli piace", 1)',
                                           @entity)
    @correct = "Simone gioca A Pallone e assolutamente non gli piace moltissimo, gli piace veramente troppo, gli piace playboy"
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned, @markup = @dc.parse_formula('substitute("aaa", "a", "b", 1)',
                                           @entity)
    @correct = "baa"
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned, @markup = @dc.parse_formula('substitute(substitute("bbb", "b",
                                                                  "a", 1),"bb",
                                                                  "bc",5)',
                                           @entity)
    @correct = "abc"
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned, @markup = @dc.parse_formula('"$"&trim("   Simone e Giulia  ")&"$"',
                                           @entity)
    @correct = "$Simone e Giulia$"
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned, @markup = @dc.parse_formula('"-"&trim("                      Simone e Giulia     ")&"-"', @entity)
    @correct = "-Simone e Giulia-"
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned, @markup = @dc.parse_formula('trim("                     Simone e Giulia     ")', @entity)
    @correct = "Simone e Giulia"
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned, @markup = @dc.parse_formula('trim( " 12   Simone e Giulia   ")',
                                           @entity)
    @correct = "12   Simone e Giulia"
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned, @markup = @dc.parse_formula('value("-1234.987")', @entity)
    @correct = -1234.987
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned, @markup = @dc.parse_formula('value("0.00000000000000000000000000
                                           00000000000000000000000000000000")',
                                           @entity)
    @correct = 0.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned, @markup = @dc.parse_formula('value("0.00000000000000000000000000
                                           00000000000000000000000000000001")',
                                           @entity)
    @correct = 0.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

#TODO(snicolo): figure out why this fails -- it depends on the number lenght 
#    @returned, @markup = @dc.parse_formula('value("23423555231234.943243287")',
#                                           @entity)
#    @correct = 23423555231234.943243287
#    prepare_result 
#    assert_equal(@correct, @returned, "the expected result: #{@correct} does
#                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('value("23423555231234.9")',
                                           @entity)
    @correct = 23423555231234.9
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('value("4.94324328733333333444")',
                                           @entity)
    @correct = 4.94324328733333333444
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned, @markup = @dc.parse_formula('proper("The Brown fox jumped over the lazy dog")', @entity)
    @correct = "The Brown Fox Jumped Over The Lazy Dog"
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned, @markup = @dc.parse_formula('proper("the Brown fOx jumPEd over the lazy dog")', @entity)
    @correct = "The Brown Fox Jumped Over The Lazy Dog"
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned, @markup = @dc.parse_formula('proper("123 The 3brown fox jumped over #the ^lazy \"dog")', @entity)
    @correct = "123 The 3brown Fox Jumped Over #the ^lazy \"dog"
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned, @markup = @dc.parse_formula('proper("d")', @entity)
    @correct = "D"
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned, @markup = @dc.parse_formula('proper("")', @entity)
    @correct = ""
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned, @markup = @dc.parse_formula('proper("-1")', @entity)
    @correct = "-1"
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned, @markup = @dc.parse_formula('proper("25")', @entity)
    @correct = "25"
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned, @markup = @dc.parse_formula('proper("25*Scott")', @entity)
    @correct = "25*scott"
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned, @markup = @dc.parse_formula('proper("25*"&"Scott")', @entity)
    @correct = "25*scott"
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned, @markup = @dc.parse_formula('proper("5*5")', @entity)
    @correct = "5*5"
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned, @markup = @dc.parse_formula('upper("5*5")', @entity)
    @correct = "5*5"    
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned, @markup = @dc.parse_formula('lower("5*5")', @entity)
    @correct = "5*5"
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned, @markup = @dc.parse_formula('proper(concatenate("simone",
                                                               " jennifer",
                                                               " luigi"))',
                                           @entity)
    @correct = "Simone Jennifer Luigi"
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned, @markup = @dc.parse_formula('(15.625-15.6249999999999)',
                                           @entity)
    @correct = 0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    @returned, @markup = @dc.parse_formula('(15.625-15.6249999999999)',
                                           @entity)
    @correct = 0.0
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned, @markup = @dc.parse_formula('(15.625-15.6249999999999)',
                                           @entity)
    @correct = 0 
    prepare_result 
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
  end

end


