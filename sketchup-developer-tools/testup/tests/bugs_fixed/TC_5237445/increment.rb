#!/usr/bin/ruby
#
# Copyright:: Copyright 2012 Trimble Navigation Ltd.
# License:: All Rights Reserved.
# Original Author:: Scott Lininger 
#
# Part of test for Buganizer Bug #5237445

# This file will be "compiled" into increment_encrypted.rbs, and then
# that will be included via Sketchup.require. It should only ever
# load in once for each file name, so the global $number_of_times_loaded
# should never get to 3.
if $number_of_times_loaded == nil
  $number_of_times_loaded = 1
else
  $number_of_times_loaded += 1
end

