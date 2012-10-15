#!/usr/bin/ruby
#
# Copyright:: Copyright 2012 Trimble Navigation Ltd.
# License:: Apache license, 
# Original Author:: Matt Lowrie
#
# Wrapper module for Win32 API constants and methods.
#

require 'win32/api'

module ApiDefs
  # Constants
  #
  # Defined in winuser.h
  #
  MOUSEEVENTF_LEFTDOWN = '0002'.hex
  MOUSEEVENTF_LEFTUP = '0004'.hex
  MOUSEEVENTF_RIGHTDOWN = '0008'.hex
  MOUSEEVENTF_RIGHTUP = '0010'.hex
  PROCESS_QUERY_INFORMATION = '0400'.hex
  PROCESS_VM_READ = '0010'.hex
  WM_COMMAND = '0111'.hex
  WM_NOTIFY = '004e'.hex

  # Attributes
  #
  @enum_child_windows = Win32::API.new('EnumChildWindows', 'LKP', 'I', 'user32')
  @enum_windows = Win32::API.new('EnumWindows', 'KP', 'L', 'user32')
  @get_class_name = Win32::API.new('GetClassName', 'LPI', 'I', 'user32')
  @get_client_rect = Win32::API.new('GetClientRect', 'LP', 'I', 'user32')
  @get_process_image_file_name = Win32::API.new('GetProcessImageFileName',
                                                'LPI', 'I', 'psapi')
  @get_window_long = Win32::API.new('GetWindowLong', 'LL', 'L', 'user32')
  @get_window_rect = Win32::API.new('GetWindowRect', 'LP', 'I', 'user32')
  @get_window_text = Win32::API.new('GetWindowText', 'LPI', 'I', 'user32')
  @get_window_thread_process_id = Win32::API.new('GetWindowThreadProcessId',
                                                 'LP', 'I','user32')
  @mouse_event = Win32::API.new('mouse_event', 'LIIII', 'I', 'user32')
  @move_window = Win32::API.new('MoveWindow', 'LIIIII', 'I', 'user32')
  @open_process = Win32::API.new('OpenProcess', 'LIL', 'I', 'kernel32')
  @send_message = Win32::API.new('SendMessage', 'LLLL', 'I', 'user32')
  @set_cursor_pos = Win32::API.new('SetCursorPos', 'II', 'I', 'user32')

  # Methods
  #
  # These wrapper methods simply return the API method object, so the call()
  # method on them still needs to be envoked, for example:
  #   ApiDefs.get_class_name.call(hwnd, buffer, buf_size)
  # Forgetting to use the call() method will result in a ArgumentError with not
  # enough arguments.
  #
  def self.enum_child_windows
    @enum_child_windows
  end

  def self.enum_windows
    @enum_windows
  end

  def self.get_class_name
    @get_class_name
  end

  def self.get_client_rect
    @get_client_rect
  end

  def self.get_process_image_file_name
    @get_process_image_file_name
  end

  def self.get_window_long
    @get_window_long
  end

  def self.get_window_rect
    @get_window_rect
  end

  def self.get_window_text
    @get_window_text
  end

  def self.get_window_thread_process_id
    @get_window_thread_process_id
  end

  def self.mouse_event
    @mouse_event
  end

  def self.move_window
    @move_window
  end

  def self.open_process
    @open_process
  end

  def self.send_message
    @send_message
  end

  def self.set_cursor_pos
    @set_cursor_pos
  end
end
