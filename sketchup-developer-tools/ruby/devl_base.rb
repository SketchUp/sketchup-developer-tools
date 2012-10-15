#!/usr/bin/ruby -w
#
# Copyright 2012 Trimble Navigation Ltd.
#
# Baseline requirements for SketchUp Developer Tools Extension.

require 'sketchup.rb'
require 'LangHandler.rb'

# Tools rely on the Ruby-JS Bridge to communicate with the Ruby engine.
Sketchup::require 'sketchup-developer-tools/ruby/devl_bridge.rb'

# Define placeholder module which is ultimately opened and augmented by the
# individual tools which load as part of the overall extension.
#
module Developer
  VERSION = '0.0.1'
end
