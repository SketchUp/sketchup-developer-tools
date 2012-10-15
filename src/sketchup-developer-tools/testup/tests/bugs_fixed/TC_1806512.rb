#!/usr/bin/ruby
#
# Copyright:: Copyright 2012 Trimble Navigation Ltd.
# License:: Apache License version 2.0
# Original Author:: Matt Lowrie 
#
# Regression test for Buganizer Bug #1806512.
#

require 'test/unit'

class TC_1806512 < Test::Unit::TestCase
  def test_1806512
    # Bringing up the message box dialog with this string crashes Mac SketchUp,
    # so unfortunately we have to show some GUI and cannot do it in memory.
    UI.messagebox "% s"
  end
end
