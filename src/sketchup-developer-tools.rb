#!/usr/bin/ruby -w
#
# Copyright 2012 Trimble Inc.
#
# Initializer for SketchUp Developer Tools Extension.

require 'sketchup.rb'
require 'extensions.rb'
require 'LangHandler.rb'

version = '0.1.0'

# Put translation object where all Developer tools can find it.
$devl_strings = LanguageHandler.new("Developer.strings")

# Load the extension via a specific loader file. Doing it via this separate
# loader file allows the rest of the package to be obfuscated Ruby.
devl_extension = SketchupExtension.new $devl_strings.GetString(
  "Developer"), "sketchup-developer-tools/ruby/devl_loader.rb"
devl_extension.version = version
devl_extension.copyright = '2012 Trimble, released under Apache 2.0'
devl_extension.description = $devl_strings.GetString("Provides a set of " +
    "tools for SketchUp Ruby Developers.")

# Register the extension with Sketchup.
Sketchup.register_extension devl_extension, true

