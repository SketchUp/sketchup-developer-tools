#!/usr/bin/ruby -w
#
# Copyright 2012 Trimble Navigation Ltd.
#
# Extension setup for SketchUp Developer Tools Extension.

require 'sketchup.rb'
require 'LangHandler.rb'

# Bring in the base first, then any tool-specific modules (like Console).
Sketchup::require 'sketchup-developer-tools/ruby/devl_base'
Sketchup::require 'sketchup-developer-tools/ruby/devl_console'
Sketchup::require 'sketchup-developer-tools/testup/testup.rb'

# If we've never loaded the tools extension then locate the top-level
# SketchUp Tools menu bar and inject a "Developer" submenu to host any
# menus related to tool submodules.
if (not $devtools_loaded) 
  $devtools_submenu = UI.menu("Tools").add_submenu(
    $devl_strings.GetString("Developer"))
  $devtools_loaded = true
end

if (not $devtools_console_loaded)
  console_cmd = UI::Command.new($devl_strings.GetString("Console")) {
    Developer::Console.new().show 
  }
  console_cmd.tooltip = $devl_strings.GetString("Developer Console")
  console_cmd.status_bar_text = $devl_strings.GetString("Open Developer Console")
  console_cmd.menu_text = $devl_strings.GetString("Console")
  $devtools_submenu.add_item(console_cmd)

  testup_cmd = UI::Command.new($devl_strings.GetString("Console")) {
    if $testup == nil
      $testup = TestUp.new
    end
    $testup.launch_gui
  }
  testup_cmd.tooltip = $devl_strings.GetString("TestUp")
  testup_cmd.status_bar_text = $devl_strings.GetString("Open TestUp")
  testup_cmd.menu_text = $devl_strings.GetString("TestUp")
  $devtools_submenu.add_item(testup_cmd)

  $devtools_console_loaded = true
end

