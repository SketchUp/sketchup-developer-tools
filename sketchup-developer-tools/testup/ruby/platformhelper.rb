#!/usr/bin/ruby
#
# Copyright:: Copyright 2012 Trimble Navigation Ltd.
# License:: Apache License, version 2.0
# Original Author:: Matt Lowrie 
#
# Uses the win32-api module to provide helper functions for manipulating
# application windows in order to perform Ruby API unit tests.
#
# $Id: //depot/eng/doc/rubyguide.html#35 $

require 'win32/api'
require 'win32/apidefs'

# Global variables!  =8-O
#
# So here is the deal with these...
# The win32-api shared object keeps a list of all registered callbacks (those
# created with Callback.new) in global scope, which is not so bad, except that
# for whatever reason it only allows you to register 10 callbacks at most. Since
# TestUp is designed to load a ruby file on each run (for development, so you
# can make changes and re-run your test script), this can fill up the callback
# list quickly. To get around this, we need to declare our window enumeration
# callback in global scope so that it is reused each test run. The better fix
# is to add a unregister_callback() function in the win32-api C code (api.c).
# TODO(mlowrie): Add unregister_callback() function to api.c
#
# Additionally, the param argument to the callback is not returned by
# reference, so within the callback we need to access storage at a higher level.
# Since we are already stored in the global scope, there is no where else to
# store our data, so we need to access a global array named $windows.
# TODO(mlowrie): Make callback class in api.c return by reference
#
$windows = []
# Only define the callback once
if $enum_windows_callback.nil?
  $enum_windows_callback = Win32::API::Callback.new('LP', 'I') { |hwnd, param|
    $windows << hwnd
    true
  }
end


# Factory class to provide a platform-specific implementation
#
class PlatformHelper
  # On instantiation, return an instance of the platform-appropriate class
  #
  def self.new
    if RUBY_PLATFORM =~ /mswin/
      return WindowsPlatformHelper.new
    else
      raise 'Not implemented for this platform yet.'
    end
  end
end


# PlatformHelper implementation for Windows
#
class WindowsPlatformHelper

  # Determines the correct window handle from the specified parameters.
  #
  # Args:
  # - title: A string or sub-string in the application window title to look for.
  # - process_name: A string or sub-string of the process name which launched
  #       the application window.
  #
  # Returns:
  # - integer: The main window handle.
  #
  def get_window_handle(title, process_name)
    # Reset the callback storage.
    $windows = []
    ApiDefs.enum_windows.call($enum_windows_callback, '')
    # First get a collection of window titles which contain the title string.
    # These could include browser or explorer windows.
    hwnds = []
    title_regexp = Regexp.new(title)
    $windows.each do |hwnd|
      # 128 byte buffer for the window title
      title = [].pack('x128')
      ApiDefs.get_window_text.call(hwnd, title, 128)
      if title_regexp =~ title:
        hwnds << hwnd
      end
    end

    # Next filter down the window handles to ones who have a process image path
    # which includes the supplied process name.
    images = {}
    process_regexp = Regexp.new(process_name)
    for hwnd in hwnds:
      # Most likely only need 8 byte buffer at most for pid
      pid_buffer = [].pack('x8')
      ApiDefs.get_window_thread_process_id.call(hwnd, pid_buffer)
      pid = pid_buffer.unpack('I')[0]
      flags = ApiDefs::PROCESS_QUERY_INFORMATION | ApiDefs::PROCESS_VM_READ
      proc = ApiDefs.open_process.call(flags, false, pid)
      # 128 byte buffer for the image name
      image_name = [].pack('x128')
      ApiDefs.get_process_image_file_name.call(proc, image_name, 128)
      if process_regexp =~ image_name
        images[hwnd] = image_name
      end
    end

    # Now if we are left with one window handle we can return it, otherwise
    # there are multiple instances of the process running and we need to
    # heuristically figure out the correct one.
    handle = nil
    if 1 == images.length
      handle = images.keys[0]
    else
      # Most likely, this file is in a similar file path as the application
      # image path, so determine the best match by how many directory names
      # are similar... and cross your fingers.
      path_names = File.expand_path(File.dirname(__FILE__)).split('/')
      high_score = 0
      for hwnd in images.keys():
        image_path = images[hwnd]
        num_matches = 0
        for n in path_names
          if image_path.include? n
            num_matches += 1
          end
        end
        if num_matches > high_score
          handle = hwnd
          high_score = num_matches
        end
      end
    end
    return handle
  end

  # Finds the window handle of a child window.
  #
  # Args:
  # - main_handle: A handle to the main window under which to search for the
  #      child window.
  # - child_window_classname: A string or sub-string of the child window class
  #       name to look for. Returns the last window found with this class.
  #
  # Returns:
  # - integer: A handle to the child window, or nil if none found.
  #
  def get_child_window_handle(main_handle, child_window_classname)
    # Reset the callback storage.
    $windows = []
    ApiDefs.enum_child_windows.call(main_handle, $enum_windows_callback, '')
    child_handle = nil
    child_window_classname_regexp = Regexp.new(child_window_classname)
    $windows.each { |hwnd|
      # 128 byte buffer for window class name
      cls_name = [].pack('x128')
      ApiDefs.get_class_name.call(hwnd, cls_name, 128)
      if child_window_classname_regexp =~ cls_name
        child_handle = hwnd
      end
    }
    return child_handle
  end

  # Resizes a window area to a specified size.
  #
  # Args:
  # - main_handle: The handle for the main window.
  # - width: The width to resize to.
  # - height: The height to resize to.
  # - child_window_classname: A class name of a child window to find. If
  #       specified, the child window will be resized to the width/height
  #       dimensions, otherwise the main window will be resized.
  #
  def resize_window(main_handle, width, height, child_window_classname=nil)
    # Find the window handle for the child window
    child_handle = nil
    if child_window_classname
      child_handle = get_child_window_handle(main_handle,
                                             child_window_classname)
    end

    resize_width = width
    resize_height = height

    if child_handle
      # 16 byte buffer for RECT struct of 4 longs
      main_rect_struct = [].pack('x16')
      ApiDefs.get_window_rect.call(main_handle, main_rect_struct)
      main_rect = main_rect_struct.unpack('I4')

      child_rect_struct = [].pack('x16')
      ApiDefs.get_client_rect.call(child_handle, child_rect_struct)
      child_rect = child_rect_struct.unpack('I4')

      # Calculate the size that the main window needs to be in order to size
      # the child window to the specified dimensions.
      resize_width += (main_rect[2] - child_rect[2])
      resize_width += (child_rect[0] - main_rect[0])

      resize_height += (main_rect[3] - child_rect[3])
      resize_height += (child_rect[1] - main_rect[1])
    end

    ApiDefs.move_window.call(main_handle, main_rect[0], main_rect[1],
                             resize_width, resize_height, true)
  end

  # Converts coordinates relative to a window into screen coordinates.
  #
  # Args:
  # - x: The window-relative horizontal coordinate.
  # - y: The window-relative vertical coordinate.
  # - main_handle: The main window which contains the coordinates.
  # - child_window_classname: (optional) When supplied, bases the coordinates
  #       relative to the child window location.
  #
  # Returns:
  # - array: [x, y] containing screen coordinates.
  #
  def get_screen_coords(x, y, main_handle, child_window_classname=nil)
    if child_window_classname
      window_handle = get_child_window_handle(main_handle,
                                              child_window_classname)
    else
      window_handle = main_handle
    end
    window_rect_struct = [].pack('x16')
    ApiDefs.get_window_rect.call(window_handle, window_rect_struct)
    window_rect = window_rect_struct.unpack('I4')
    return [window_rect[0] + x, window_rect[1] + y]
  end

  # Performs a left-mouse click at the supplied screen coordinates.
  #
  # Args:
  # - x: The horizontal screen coordinate to click at.
  # - y: The vertical screen coordinate to click at.
  #
  def click_left_mouse(x, y)
    ApiDefs.set_cursor_pos.call(x, y)
    ApiDefs.mouse_event.call(ApiDefs::MOUSEEVENTF_LEFTDOWN, x, y, 0, 0)
    sleep(0.05)
    ApiDefs.mouse_event.call(ApiDefs::MOUSEEVENTF_LEFTUP, x, y, 0, 0)
  end
end
