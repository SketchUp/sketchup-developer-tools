#
# Copyright:: Copyright 2012 Trimble Navigation Ltd.
# License:: Apache License version 2.0
# Original Author:: Simone Nicolo 
#

require 'sketchup.rb'
require 'test/unit'

#
# This Unit tests are used for testing the Unit Conversion Engine for DCs.
#
# Below is a list of the supported units and their base units
#   (Unit => BaseUnit)
#   DEFAULT=>INCHES
#   INTEGER => INTEGER
#   FLOAT => FLOAT
#   PERCENT => FLOAT
#   BOOLEAN => BOOLEAN
#   STRING => STRING
#   INCHES => INCHES
#   FEET => INCHES
#   MILLIMETERS => INCHES
#   CENTIMETERS => INCHES
#   METERS => INCHES
#   DEGREES => DEGREES
#   DOLLARS => DOLLARS
#   EUROS => DOLLARS
#   YEN => DOLLARS
#   POUNDS => POUNDS
#   KILOGRAMS => POUNDS
#

class DCMetricTests < Test::Unit::TestCase
  
  @@DC_TRUE = 1.0
  @@DC_FALSE = 0.0
  @@ACCURACY = 6

  def setup
    #Assets for this test case
    @converter = DCConverter.new
    @correct = nil
    @incorrect = nil
    @returned = nil
  end

  # This function rounds floating point numbers to the specified decimal place
  #
  # Args:
  #   fp_number: the floating point number to round
  #   d_place: the decimal place to round to
  #
  # Returns:
  #   returns a float rounded to the specified decimal place
  def round_float(fp_number, d_place)
    assert_nothing_raised do
      return (fp_number * 10**d_place).round.to_f / 10**d_place
    end
  end
  
  # This function prepares the results to be compared by truncating floating 
  # points numbers to the value specified in @@ACCURACY and puts them in the
  # class variables @correct, @incorrect and @returned
  # 
  # Args:
  #   expected - value we expect
  # 
  # Returns:
  #   None
  def prepare_result(expected)
    assert_nothing_raised do
      if expected.kind_of? Integer 
        @returned = @returned.to_f
        @correct = expected.to_f
        @incorrect = expected.to_f
      elsif expected.kind_of? Float
        @returned = round_float(@returned.to_f, @@ACCURACY)
        @correct = round_float(expected, @@ACCURACY)
        @incorrect = round_float(expected, @@ACCURACY)
      else
        @returned = @returned
        @correct = expected
        @incorrect = expected
      end
    #debug info
    #puts "expected: #{@correct} - returned: #{@returned}"
    end
  end


  # This function runs test to verify that the conversion of length is 
  # done correctly to the base unit of Inches.
  #
  # In order to add a test you can use the following template
  #   ------------------------------------------------------ 
  #   
  #   #this will convert the Value in the specified Unit into Inches
  #   @returned = eval('@converter.to_base('<VALUE>', "UNIT")')
  #   
  #   #this step is used to avoid computer arithmetic errors 
  #   prepare_result(<Expected Result>)
  #
  #   assert_equal(@correct, @returned, "The expected result: #{@correct} does
  #                not match the returned result #{@returned}")
  #   
  #   #Or for comparison that you are expecting to fail you can use
  #   assert_not_equal(@correct, @returned, "The incorrect result: #{@incorrect}
  #                    does match the returned result #{@returned}")
  #   ------------------------------------------------------
  #
  # Args:
  #   None
  # Returns:
  #   None
  def test_length_to_base
    @returned = eval('@converter.to_base(25.47, "DEFAULT")')  
    prepare_result(25.47)
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
     
    @returned = eval('@converter.to_base(25.4, "MILLIMETERS")')  
    prepare_result(1.0)
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned = eval('@converter.to_base(11.75, "INCHES")')  
    prepare_result(11.75)
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned = eval('@converter.to_base(2.54, "CENTIMETERS")')  
    prepare_result(1.0)
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned = eval('@converter.to_base(0.0254, "METERS")')  
    prepare_result(1.0)
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned = eval('@converter.to_base("25.40", "MILLIMETERS")')  
    prepare_result(1.0)
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned = eval('@converter.to_base("02.54", "CENTIMETERS")')  
    prepare_result(1.0)
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned = eval('@converter.to_base("0.025400", "METERS")')  
    prepare_result(1.0)
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
 
    @returned = eval('@converter.to_base(1.0, "FEET")')  
    prepare_result(12.0)
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned = eval('@converter.to_base(1.5, "FEET")')  
    prepare_result(18.0)
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned = eval('@converter.to_base(-25.47, "DEFAULT")')  
    prepare_result(-25.47)
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
     
    @returned = eval('@converter.to_base(-25.4, "MILLIMETERS")')  
    prepare_result(-1.0)
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned = eval('@converter.to_base(-11.75, "INCHES")')  
    prepare_result(-11.75)
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned = eval('@converter.to_base(-2.54, "CENTIMETERS")')  
    prepare_result(-1.0)
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned = eval('@converter.to_base(-0.0254, "METERS")')  
    prepare_result(-1.0)
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned = eval('@converter.to_base("-25.40", "MILLIMETERS")')  
    prepare_result(-1.0)
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned = eval('@converter.to_base("-02.54", "CENTIMETERS")')  
    prepare_result(-1.0)
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned = eval('@converter.to_base("-0.025400", "METERS")')  
    prepare_result(-1.0)
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned = eval('@converter.to_base(-1.0, "FEET")')  
    prepare_result(-12.0)
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned = eval('@converter.to_base(-1.5, "FEET")')  
    prepare_result(-18.0)
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")             

    #test for some failures
    @returned = eval('@converter.to_base(25.4, "MILLIMETERS")')  
    prepare_result(1.01)
    assert_not_equal(@incorrect, @returned, "the incorrect result: #{@incorrect} 
                     does match the returned result #{@returned}")
    
    @returned = eval('@converter.to_base(2.54, "CENTIMETERS")')  
    prepare_result(1.01)
    assert_not_equal(@incorrect, @returned, "the incorrect result: #{@incorrect} 
                     does match the returned result #{@returned}")
    
    @returned = eval('@converter.to_base(0.0254, "METERS")')  
    prepare_result(1.01)
    assert_not_equal(@incorrect, @returned, "the incorrect result: #{@incorrect} 
                     does match the returned result #{@returned}")
    
    @returned = eval('@converter.to_base("25.40", "MILLIMETERS")')  
    prepare_result(1.01)
    assert_not_equal(@incorrect, @returned, "the incorrect result: #{@incorrect}
                     does not match the returned result #{@returned}")
    
    @returned = eval('@converter.to_base("02.54", "CENTIMETERS")')  
    prepare_result(1.01)
    assert_not_equal(@incorrect, @returned, "the incorrect result: #{@incorrect} 
                     does match the returned result #{@returned}")
    
    @returned = eval('@converter.to_base("0.025400", "METERS")')  
    prepare_result(1.01)
    assert_not_equal(@incorrect, @returned, "the incorrect result: #{@incorrect} 
                     does match the returned result #{@returned}")

    @returned = eval('@converter.to_base(1.0, "FEET")')  
    prepare_result(12.01)
    assert_not_equal(@incorrect, @returned, "the incorrect result: #{@incorrect}
                     does match the returned result #{@returned}")
    
    @returned = eval('@converter.to_base(1.5, "FEET")')  
    prepare_result(18.1)
    assert_not_equal(@incorrect, @returned, "the incorrect result: #{@incorrect}
                     does match the returned result #{@returned}")
    
  end

  # This function runs test to verify that the conversion of length is 
  # done correctly from the base unit of Inches.
  #
  #In order to add a test you can use the following template
  #   ------------------------------------------------------ 
  #   
  #   #this will convert the Value in the specified Unit into Inches
  #   @returned = eval('@converter.to_base('<VALUE>', "UNIT")')
  #   
  #   #this step is used to avoid computer arithmetic errors 
  #   prepare_result(<Expected Result>)
  #
  #   assert_equal(@correct, @returned, "The expected result: #{@correct} does
  #                not match the returned result #{@returned}")
  #   
  #   #Or for comparison that you are expecting to fail you can use
  #   assert_not_equal(@correct, @returned, "The incorrect result: #{@incorrect}
  #                    does match the returned result #{@returned}")
  #   ------------------------------------------------------
  #
  # Args:
  #   None
  # Returns:
  #   None
  def test_length_from_base              
    # Test conversions from the base unit of Inches into other units
    @returned = eval('@converter.from_base(25.47, "DEFAULT")')  
    prepare_result(25.47)
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned = eval('@converter.from_base(2, "CENTIMETERS")')  
    prepare_result(5.08)
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned = eval('@converter.from_base(1, "MILLIMETERS")')  
    prepare_result(25.4)
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned = eval('@converter.from_base(100, "METERS")')  
    prepare_result(2.54)
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned = eval('@converter.from_base("2.00", "CENTIMETERS")')  
    prepare_result(5.08)
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned = eval('@converter.from_base("0001.00", "MILLIMETERS")')  
    prepare_result(25.4)
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned = eval('@converter.from_base("100.00", "METERS")')  
    prepare_result(2.54)
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned = eval('@converter.from_base(12, "FEET")')  
    prepare_result(1.0)
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned = eval('@converter.from_base(18, "FEET")')  
    prepare_result(1.5)
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
 
    @returned = eval('@converter.from_base("100cm", "METERS")')  
    prepare_result(2.54)
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned = eval('@converter.from_base("$1,00", "STRING")')  
    prepare_result("$1,00")
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned = eval('@converter.from_base("$10,0", "STRING")')  
    prepare_result("$10,0")
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned = eval('@converter.from_base(12, "STRING")')  
    prepare_result(12)
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                not match the returned result #{@returned}")

    @returned = eval('@converter.from_base("12", "STRING")')  
    prepare_result("12")
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")   

    @returned = eval('@converter.from_base(34.4, "STRING")')  
    prepare_result(34.4)
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                  not match the returned result #{@returned}")

    @returned = eval('@converter.from_base(1.1234567, "STRING")')  
    prepare_result(1.1234567)
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned = eval('@converter.from_base("1.12345678901234", "STRING")')  
    prepare_result("1.12345678901234")
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    #NOTE: these tests will fail until we provide Currency conversions
    #prepare_result(2.54)
    #assert_equal(@correct, @returned, "the expected result: #{@correct} does
    #             not match the returned result #{@returned}")   

    #@returned = eval('@converter.from_base("$100", "METERS")')  
    #prepare_result(2.54)
    #assert_equal(@correct, @returned, "the expected result: #{@correct} does
    #             not match the returned result #{@returned}")

    #@returned = eval('@converter.from_base("$1,00", "METERS")')  
    #prepare_result(2.54)
    #assert_equal(@correct, @returned, "the expected result: #{@correct} does
    #             not match the returned result #{@returned}")

    @returned = eval('@converter.from_base(-25.47, "DEFAULT")')  
    prepare_result(-25.47)
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned = eval('@converter.from_base(-2, "CENTIMETERS")')  
    prepare_result(-5.08)
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned = eval('@converter.from_base(-1, "MILLIMETERS")')  
    prepare_result(-25.4)
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned = eval('@converter.from_base(-100, "METERS")')  
    prepare_result(-2.54)
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned = eval('@converter.from_base("-2.00", "CENTIMETERS")')  
    prepare_result(-5.08)
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned = eval('@converter.from_base("-0001.00", "MILLIMETERS")')  
    prepare_result(-25.4)
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned = eval('@converter.from_base("-100.00", "METERS")')  
    prepare_result(-2.54)
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned = eval('@converter.from_base(-12, "FEET")')  
    prepare_result(-1.0)
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned = eval('@converter.from_base(-18, "FEET")')  
    prepare_result(-1.5)
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
 
    @returned = eval('@converter.from_base("-100cm", "METERS")')  
    prepare_result(-2.54)
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")
    
    @returned = eval('@converter.from_base("$-1,00", "STRING")')  
    prepare_result("$-1,00")
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned = eval('@converter.from_base("-$10,0", "STRING")')  
    prepare_result("-$10,0")
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned = eval('@converter.from_base(-12, "STRING")')  
    prepare_result(-12)
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                not match the returned result #{@returned}")

    @returned = eval('@converter.from_base("-12", "STRING")')  
    prepare_result("-12")
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")   

    @returned = eval('@converter.from_base(-34.4, "STRING")')  
    prepare_result(-34.4)
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                  not match the returned result #{@returned}")

    @returned = eval('@converter.from_base(-1.1234567, "STRING")')  
    prepare_result(-1.1234567)
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned = eval('@converter.from_base("-1.12345678901234", "STRING")')  
    prepare_result("-1.12345678901234")
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    #NOTE: these tests will fail until we provide Currency conversions  
    #@returned = eval('@converter.from_base("$-10,0", "METERS")')  
    #prepare_result(-2.54)
    #assert_equal(@correct, @returned, "the expected result: #{@correct} does
    #             not match the returned result #{@returned}")   

    #@returned = eval('@converter.from_base("$-100", "METERS")')  
    #prepare_result(-2.54)
    #assert_equal(@correct, @returned, "the expected result: #{@correct} does
    #             not match the returned result #{@returned}")

    #@returned = eval('@converter.from_base("-$1,00", "METERS")')  
    #prepare_result(-2.54)
    #assert_equal(@correct, @returned, "the expected result: #{@correct} does
    #             not match the returned result #{@returned}")

    #test for some failures
    @returned = eval('@converter.from_base(2, "CENTIMETERS")')  
    prepare_result(5.081)
    assert_not_equal(@incorrect, @returned, "the incorrect result: #{@incorrect}
                     does match the returned result #{@returned}")
    
    @returned = eval('@converter.from_base(1, "MILLIMETERS")')  
    prepare_result(25.41)
    assert_not_equal(@incorrect, @returned, "the incorrect result: #{@incorrect}
                     does match the returned result #{@returned}")
    
    @returned = eval('@converter.from_base(100, "METERS")')  
    prepare_result(2.541)
    assert_not_equal(@incorrect, @returned, "the incorrect result: #{@incorrect}
                     does match the returned result #{@returned}")
    
    @returned = eval('@converter.from_base("2.00", "CENTIMETERS")')  
    prepare_result(5.081)
    assert_not_equal(@incorrect, @returned, "the incorrect result: #{@incorrect}
                     does match the returned result #{@returned}")
    
    @returned = eval('@converter.from_base("0001.00", "MILLIMETERS")')  
    prepare_result(25.41)
    assert_not_equal(@incorrect, @returned, "the incorrect result: #{@incorrect}
                     does match the returned result #{@returned}")
    
    @returned = eval('@converter.from_base("100.00", "METERS")')  
    prepare_result(2.541)
    assert_not_equal(@incorrect, @returned, "the incorrect result: #{@incorrect}
                     does match the returned result #{@returned}")

    @returned = eval('@converter.from_base("100cm", "METERS")')  
    prepare_result(2.541)
    assert_not_equal(@incorrect, @returned, "the incorrect result: #{@incorrect}
                     does match the returned result #{@returned}")

    @returned = eval('@converter.from_base("$100", "METERS")')  
    prepare_result(2.541)
    assert_not_equal(@incorrect, @returned, "the incorrect result: #{@incorrect} 
                     does match the returned result #{@returned}")

    @returned = eval('@converter.from_base("$1,00", "METERS")')  
    prepare_result(2.541)
    assert_not_equal(@incorrect, @returned, "the incorrect result: #{@incorrect} 
                     does match the returned result #{@returned}")

    @returned = eval('@converter.from_base("$10,0", "METERS")')  
    prepare_result(2.541)
    assert_not_equal(@incorrect, @returned, "the incorrect result: #{@incorrect}
                     does match the returned result #{@returned}")

    @returned = eval('@converter.from_base(12, "FEET")')  
    prepare_result(1.01)
    assert_not_equal(@incorrect, @returned, "the incorrect result: #{@incorrect} 
                     does match the returned result #{@returned}")

    @returned = eval('@converter.from_base(18, "FEET")')  
    prepare_result(1.51)
    assert_not_equal(@incorrect, @returned, "the incorrect result: #{@incorrect}
                     does match the returned result #{@returned}")

    @returned = eval('@converter.from_base("$1,00", "STRING")')  
    prepare_result("$1,01")
    assert_not_equal(@incorrect, @returned, "the incorrect result: #{@incorrect}
                     does match the returned result #{@returned}")

    @returned = eval('@converter.from_base("$10,0", "STRING")')  
    prepare_result("$10,01")
    assert_not_equal(@incorrect, @returned, "the incorrect result: #{@incorrect}
                     does match the returned result #{@returned}")

    @returned = eval('@converter.from_base(12, "STRING")')  
    prepare_result(12.1)
    assert_not_equal(@incorrect, @returned, "the incorrect result: #{@incorrect}
                     does match the returned result #{@returned}")

    @returned = eval('@converter.from_base("12", "STRING")')  
    prepare_result("12.1")
    assert_not_equal(@incorrect, @returned, "the incorrect result: #{@incorrect}
                     does match the returned result #{@returned}")   

    @returned = eval('@converter.from_base(34.4, "STRING")')  
    prepare_result(34.41)
    assert_not_equal(@incorrect, @returned, "the incorrect result: #{@incorrect}
                     match the returned result #{@returned}")

    @returned = eval('@converter.from_base(1.123457, "STRING")')  
    prepare_result(1.123456)
    assert_not_equal(@incorrect, @returned, "the incorrect result: #{@incorrect}
                     match the returned result #{@returned}")

    @returned = eval('@converter.from_base("1.12345678901234", "STRING")')  
    prepare_result("1.123455")
    assert_not_equal(@incorrect, @returned, "the incorrect result: #{@incorrect}
                     does match the returned result #{@returned}")
  end

  # This function runs test to verify that the conversion of weight is 
  # done correctly from and to the base unit of Kilograms.
  #
  # In order to add a test you can use the following template
  #   ------------------------------------------------------ 
  #   
  #   #this will convert the Value in the specified Unit into Inches
  #   @returned = eval('@converter.to_base('<VALUE>', "UNIT")')
  #   
  #   #this step is used to avoid computer arithmetic errors 
  #   prepare_result(<Expected Result>)
  #
  #   assert_equal(@correct, @returned, "The expected result: #{@correct} does
  #                not match the returned result #{@returned}")
  #   
  #   #Or for comparison that you are expecting to fail you can use
  #   assert_not_equal(@correct, @returned, "The incorrect result: #{@incorrect}
  #                    does match the returned result #{@returned}")
  #   ------------------------------------------------------
  #
  # Args:
  #   None
  # Returns:
  #   None
  def test_weight_units
    # Test Pounds into/from Kilograms(base unit)
    
    @returned = eval('@converter.to_base(1, "POUNDS")')  
    prepare_result(1)
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned = eval('@converter.from_base(6, "POUNDS")')  
    prepare_result(6)
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    
    @returned = eval('@converter.to_base(1, "KILOGRAMS")')  
    prepare_result(2.20462262)
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    
    @returned = eval('@converter.from_base(6, "KILOGRAMS")')  
    prepare_result(2.72155422)
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    #test for some failures
    @returned = eval('@converter.to_base(1, "POUNDS")')  
    prepare_result(0.45361)
    assert_not_equal(@incorrect, @returned, "the incorrect result: #{@incorrect}
                     does match the returned result #{@returned}")

    @returned = eval('@converter.from_base(6, "POUNDS")')  
    prepare_result(13.2281)
    assert_not_equal(@incorrect, @returned, "the incorrect result: #{@incorrect}
                     does match the returned result #{@returned}")
  end

  # This function runs test to verify that the conversion of currency is 
  # done correctly from and to the base unit of Dollars
  #
  # In order to add a test you can use the following template
  #   ------------------------------------------------------ 
  #   <RESULT YOU EXPECT>
  #   
  #   #this will convert the Value in Inches into the specified Unit 
  #   @returned = eval('@converter.from_base('<VALUE>', "UNIT")')
  #    OR 
  #   #this will convert the Value in Inches into the specified Unit 
  #   @returned = eval('@converter.to_base('<VALUE>', "UNIT")')
  #   
  #   prepare_result() #this step is used to avoid computer arithmetic errors 
  #   assert_equal(@correct, @returned, "The expected result: #{@correct} does
  #                not match the returned result #{@returned}")
  #   ------------------------------------------------------
  #
  # Args:
  #   None
  # Returns:
  #   None  
  def test_currency_units
    #TODO(snicolo): When the currency unit conversion is implemented these
    # tests will fail and will need to be rewritten
     
    @returned = eval('@converter.to_base(9999.99, "DOLLARS")')  
    prepare_result(9999.99)
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned = eval('@converter.to_base(9999.99, "DOLLARS")')  
    prepare_result(9999.98)
    assert_not_equal(@incorrect, @returned, "the incorrect result: #{@incorrect}
                     does match the returned result #{@returned}")

    @returned = eval('@converter.from_base(9999.99, "DOLLARS")')  
    prepare_result(9999.99)
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned = eval('@converter.from_base(9999.99, "DOLLARS")')  
    prepare_result(9999.98)
    assert_not_equal(@incorrect, @returned, "the incorrect result: #{@incorrect}
                     does match the returned result #{@returned}")

    @returned = eval('@converter.to_base(9999.99, "YEN")')  
    prepare_result(9999.99)
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned = eval('@converter.to_base(9999.99, "YEN")')  
    prepare_result(9999.98)
    assert_not_equal(@incorrect, @returned, "the incorrect result: #{@incorrect}
                     does match the returned result #{@returned}")

    @returned = eval('@converter.from_base(9999.99, "YEN")')  
    prepare_result(9999.99)
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned = eval('@converter.from_base(9999.99, "YEN")')  
    prepare_result(9999.98)
    assert_not_equal(@incorrect, @returned, "the incorrect result: #{@incorrect}
                     does match the returned result #{@returned}")

    @returned = eval('@converter.to_base(9999.99, "EUROS")')  
    prepare_result(9999.99)
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned = eval('@converter.to_base(9999.99, "EUROS")')  
    prepare_result(9999.98)
    assert_not_equal(@incorrect, @returned, "the incorrect result: #{@incorrect}
                     does match the returned result #{@returned}")

    @returned = eval('@converter.from_base(9999.99, "EUROS")')  
    prepare_result(9999.99)
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned = eval('@converter.from_base(9999.99, "EUROS")')  
    prepare_result(9999.98)
    assert_not_equal(@incorrect, @returned, "the incorrect result: #{@incorrect}
                     does match the returned result #{@returned}")
  end

  # This function runs test to verify that the conversion of types is 
  # done correctly from and to the base types.
  #
  # In order to add a test you can use the following template
  #   ------------------------------------------------------ 
  #   
  #   #this will convert the Value in the specified Unit into Inches
  #   @returned = eval('@converter.to_base('<VALUE>', "UNIT")')
  #   
  #   #this step is used to avoid computer arithmetic errors 
  #   prepare_result(<Expected Result>)
  #
  #   assert_equal(@correct, @returned, "The expected result: #{@correct} does
  #                not match the returned result #{@returned}")
  #   
  #   #Or for comparison that you are expecting to fail you can use
  #   assert_not_equal(@correct, @returned, "The incorrect result: #{@incorrect}
  #                    does match the returned result #{@returned}")
  #   ------------------------------------------------------
  #
  # Args:
  #   None
  # Returns:
  #   None  
  def test_math_types
    
    @returned = eval('@converter.to_base(720.09, "DEGREES")')  
    prepare_result(720.09)
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned = eval('@converter.to_base(-90.01, "DEGREES")')  
    prepare_result(-90.01)
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned = eval('@converter.from_base(12, "INTEGER")')  
    prepare_result(12)
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned = eval('@converter.to_base("12", "INTEGER")')  
    prepare_result(12)
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned = eval('@converter.from_base("12", "INTEGER")')  
    prepare_result(12)
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")  

    @returned = eval('@converter.to_base(12.654, "INTEGER")')  
    prepare_result(12.654)
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned = eval('@converter.from_base(12, "INTEGER")')  
    prepare_result(12)
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned = eval('@converter.to_base("12", "INTEGER")')  
    prepare_result(12)
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned = eval('@converter.from_base("12", "INTEGER")')  
    prepare_result(12)
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")  
  
    @returned = eval('@converter.to_base("12.9975", "FLOAT")')  
    prepare_result(12.9975)
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned = eval('@converter.from_base("12.9975", "FLOAT")')  
    prepare_result(12.9975)
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned = eval('@converter.to_base(12.9975, "FLOAT")')  
    prepare_result(12.9975)
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned = eval('@converter.from_base(12.9975, "FLOAT")')  
    prepare_result(12.9975)
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")  
 
    @returned = eval('@converter.to_base("12.9975", "PERCENT")')  
    prepare_result(0.129975)
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned = eval('@converter.from_base("0.9975", "PERCENT")')  
    prepare_result(99.75)
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned = eval('@converter.to_base(12.9975, "PERCENT")')  
    prepare_result(0.129975)
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned = eval('@converter.from_base(0.9975, "PERCENT")')  
    prepare_result(99.75)
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned = eval('@converter.to_base("421343.99", "BOOLEAN")')  
    prepare_result(421343.99)
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned = eval('@converter.from_base("1.0", "BOOLEAN")')  
    prepare_result(1.0)
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned = eval('@converter.to_base(12.9975, "BOOLEAN")')  
    prepare_result(12.9975)
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")

    @returned = eval('@converter.from_base(0.0, "BOOLEAN")')  
    prepare_result(0.0)
    assert_equal(@correct, @returned, "the expected result: #{@correct} does
                 not match the returned result #{@returned}")  
  end  

end
