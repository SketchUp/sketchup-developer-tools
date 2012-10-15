#!/usr/bin/ruby
#
# Copyright 2012 Trimble Navigation Ltd.
#
# Loader for SketchUp Developer Tools Extension.
#
# We use a "two step" process from ../sketchup-developer-tools.rb to this file
# to support the loading of obfuscated Ruby versions of this extensions.
#
require 'sketchup.rb'

Sketchup::require 'sketchup-developer-tools/ruby/devl_setup'
