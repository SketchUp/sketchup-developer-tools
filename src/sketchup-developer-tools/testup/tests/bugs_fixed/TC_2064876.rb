#!/usr/bin/ruby
#
# Copyright:: Copyright 2012 Trimble Navigation Ltd.
# License:: Apache License version 2.0
# Original Author:: Simone Nicolo 
#
# Regression test for Buganizer Bug #2064876
#


require 'test/unit'

# The main test class.
# Here we are testing that bug 2064876 has not introduced any regression
# in loading files.
class TC_2064876 < Test::Unit::TestCase

  #This test loads encrypted and unencrypted files from the
  # TC_2064876/FilesToLoad directory using require_all
  # LoadTest1.rb define a class named LoadTest1
  # LoadTest2.rb define a class named LoadTest2
  # LoadTest3.rbs define a class named LoadTest3
  # LoadTest4.rbs define a class named LoadTest4
  # No class named LoadTest0 is ever defined

   def test_2064876
    local_path = __FILE__.slice(0, __FILE__.rindex('.'))
    # The files to load are in a subdirectory two deep to avoid
    # TestUp loading them automatically
    files_dir = File.join(local_path, "FilesToLoad")
    require_all files_dir

  # This should fail since no class named LoadTest0 is defined in the
  # 4 loaded files
  assert_raise NameError do
    l0 = LoadTest0.new("3", "42")
  end

  assert_nothing_raised do
    l1 = LoadTest1.new(2, 3)
    # test that we are an instance of the right class
    assert_instance_of LoadTest1, l1, "l1 is NOT an instance of LoadTest1"
    # test that we are of the right kind
    assert_kind_of LoadTest1, l1, "l1 is NOT of LoadTest1 kind"
    # test that we are not an instance of the superclass
    assert_equal((l1.instance_of?(Object)), false,
                 "l1 is an instance of Object")
    # test that we are of the kind of the superclass
    assert(l1.kind_of?(Object), "l1 is NOT of Object kind")
    # test that we are not of the String kind
    assert_equal((l1.kind_of?(String)), false, "l1 is kind of String")
  end

  assert_nothing_raised do
    l2 = LoadTest2.new(2, 3)
    # test that we are an instance of the right class
    assert_instance_of LoadTest2, l2, "l2 is NOT an instance of LoadTest2"
    # test that we are of the right kind
    assert_kind_of LoadTest2, l2, "l2 is NOT of LoadTest2 kind"
    # test that we are not an instance of the superclass
    assert_equal((l2.instance_of?(Object)), false,
                 "l2 is an instance of Object")
    # test that we are of the kind of the superclass
    assert(l2.kind_of?(Object), "l2 is NOT of Object kind")
    # test that we are not of the String kind
    assert_equal((l2.kind_of?(String)), false, "l2 is kind of String")
  end

  assert_nothing_raised do
    l3 = LoadTest3.new(2, 3)
    # test that we are an instance of the right class
    assert_instance_of LoadTest3, l3, "l3 is NOT an instance of LoadTest3"
    # test that we are of the right kind
    assert_kind_of LoadTest3, l3, "l3 is NOT of LoadTest3 kind"
    # test that we are not an instance of the superclass
    assert_equal((l3.instance_of?(Object)), false,
                 "l3 is an instance of Object")
    # test that we are of the kind of the superclass
    assert(l3.kind_of?(Object), "l3 is NOT of Object kind")
    # test that we are not of the String kind
    assert_equal((l3.kind_of?(String)), false, "l3 is kind of String")
  end

  assert_nothing_raised do
    l4 = LoadTest4.new(2, 3)
    # test that we are an instance of the right class
    assert_instance_of LoadTest4, l4, "l4 is NOT an instance of LoadTest4"
    # test that we are of the right kind
    assert_kind_of LoadTest4, l4, "l4 is NOT of LoadTest4 kind"
    # test that we are not an instance of the superclass
    assert_equal((l4.instance_of?(Object)), false,
                 "l4 is an instance of Object")
    # test that we are of the kind of the superclass
    assert(l4.kind_of?(Object), "l4 is NOT of Object kind")
    # test that we are not of the String kind
    assert_equal((l4.kind_of?(String)), false, "l4 is kind of String")
  end

  end
end

