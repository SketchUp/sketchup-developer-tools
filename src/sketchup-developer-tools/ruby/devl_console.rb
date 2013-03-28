#!/usr/bin/ruby -w
#
# Copyright:: Copyright 2012 Trimble Navigation Ltd.
# License:: Apache License, Version 2.0
#
# The Developer Console is a command-line interface to Ruby and JavaScript.
# Major goals of the console are multi-line input, reloading of scripts
# without requiring a SketchUp restart, and a high level of control over
# output processing. This latter aspect includes being able to turn off
# console output during performance-sensitive operations, being able to
# write the console output to a log file, altering font size, etc.

require 'sketchup.rb'
require 'LangHandler.rb'

# Make sure we load base which brings in bridge and common infrastructure.
Sketchup::require 'sketchup-developer-tools/ruby/devl_base.rb'

# Reopen the DeveloperTools module so our console class can be a part of
# the overall tools module.
#
module Developer

# The Console ruby class acts as a form of "server" which responds to any
# requests from the console.js code which require Ruby. The most obvious of
# these requests are those that evaluate Ruby input from the user and those
# that interact with the file system for loading or saving information.
#
class Console

  # Default parameters for operation. These can be overwritten if a
  # viable config.rb file is found and loaded during instance setup.
  @@config = {
    :x => 0,                          # left coordinate on opening
    :y => 0,                          # top coordinate on opening
    :width => 711,                    # default width (roughly 1.618 h)
    :height => 440,                   # default height (usable of 800x600)
    :minwidth => 450,                 # keep toolbar from clip/float
    :minheight => 175,                # keep 3-5 lines of content visible

    :consolemax => 1,                 # only 1 console by default
    :history => 'etc/history.rb',     # standard history cache file
    :historymax => 50,                # maximum entries kept in JS
    :inverse => false,                # standard black-on-white foramt
    :logfile => 'console.log',        # standard log file location
    :logtime => true,                 # should logs include timestamp
    :reload => /[pP]lugins/,             # reload plugins only normally
    :shiftexec => false,              # execute on Shift-Enter, not enter

    :toolroot => File.dirname(File.dirname(__FILE__)), # where is extension installed?
    :toolhelp => 'http://code.google.com/apis/sketchup/docs/tutorial_console.html',
    :usercss => '',                   # user-supplied css overlay file
    :userjs => '',                    # user-supplied JS overlay file
    :userrb => ''                     # user-supplied Ruby overlay file
  }

  # Default history list for prior session history. Loaded based on any
  # stored history found in the :history file reference in @@config.
  @@history = []

  # Should logging to a file occur during output processing? Defaults to
  # false since this is a performance drain. This is updated by each console
  # instance as they execute so it's accessible to the puts call.
  @@logging = false

  # Backdoor secondary flag to ensure no unwanted logging occurs when
  # manipulating logging and/or quiet mode states.
  @@nolog = false

  # Should puts output processing be discarded. Defaults to false so Ruby
  # error messages and other feedback are available. This is updated by each
  # console instance during execution so it's accessible to the puts call.
  @@quiet = false

  # Protect ourselves against reload effectively disabling the console by
  # clearing our key class-level variables.
  if (!defined? @@instances)

    # Keep a list of dialog references so we can try to maintain some context
    # at least within the current session.
    @@instances = []

    # Which dialog instance is the "Root Console". This is the only dialog
    # which will receive puts redirection output. The system console instance
    # is the first dialog opened when no other dialogs are currently present.
    @@rootConsole = nil

  end

  # Returns the path to the currently defined console history file.
  #
  #
  # Returns:
  # - path:  String, the fully-qualified history file name.
  #
  def self.history_file
    # Note that this relies on the current file being in a subdirectory such
    # as the 'ruby' subdirectory of the overall extension.
    dir = File.dirname(__FILE__)
    file = @@config[:history]
    path = dir + '/../' + file
    return path
  end

  # Returns the path to the currently defined console log file.
  #
  #
  # Returns:
  # - path: String, the fully-qualified log file name.
  #
  def self.log_file
    # Note that this relies on the current file being in a subdirectory such
    # as the 'ruby' subdirectory of the overall extension.
    dir = File.dirname(__FILE__)
    file = @@config[:logfile]
    path = dir + '/../' + file
    return path
  end

  # Sets the default logging flag for all consoles. Individual consoles can
  # override this setting based on their configuration at execution time.
  #
  #
  # Args:
  # - flag: Boolean, a value which should be true to activate logging.
  #
  def self.logging=(flag)
    logging = (flag == true || flag == 'true')
    if (logging != @@logging)
      msg = 'Logging ' + (logging ? 'enabled. Output is now being saved to ' +
            'Plugins/Developer/console.log' : 'disabled.')

      # If we're changing log state we always log that, then we set the new
      # value.
      @@logging = true
      puts $devl_strings.GetString(msg) unless @@nolog
      @@logging = logging
    end
  end

  # Returns the current default logging state for console instances.
  #
  #
  # Returns:
  # - flag: Boolean, true when logging is active by default.
  #
  def self.logging?
    return @@logging == true
  end

  # Returns the current timestamping state for console instances.
  #
  #
  # Returns:
  # - flag: Boolean, true when logging is active by default.
  #
  def self.timestamp?
    return @@config[:logtime] == true
  end

  # Allocates and initializes a new instance. We override this here so that
  # we can reuse instances of dialog during SketchUp sessions. If a dialog
  # has already been opened and a new dialog request is made the first
  # non-visible dialog will be re-shown. No new instance is actually created
  # in that case.
  #
  #
  # Returns:
  # - console: Developer::Console, a properly configured console instance.
  #
  def self.new

    # Regardless of consolemax setting we find the first previously valid
    # console instance that isn't visible and show that if we find one.
    if @@instances.length > 0
      dialog = @@instances.find {|dlg| !dlg.visible? }
    end

    # If we didn't find a previous instance we have to look to consolemax
    # vs. the current length of the instances list before we can decide what
    # to do next. When we have "room" to create a new instance we call
    # super to get it built. If there's a reason why we have no console yet
    # we create one, otherwise we return the first instance (root console).
    if dialog.nil?

      if @@config[:consolemax] > @@instances.length
        return super
      elsif @@instances.length == 0
        return super
      else
        return @@instances[0]
      end
    else
      return dialog
    end

  end

  # Turns off logging of state changes, particularly to the logging and
  # quiet mode flags which have to sometimes be manipulated behind the
  # scenes.
  def self.nolog=(flag)
    nolog = (flag == true || flag == 'true')
    @@nolog = nolog
  end

  # Returns the current nolog state change logging flag value.
  #
  #
  # Returns:
  # - flag: Boolean, true when no logging of state flags should occur.
  def self.nolog?
  end

  # Sends output to the current "Root Console" if that dialog exists and
  # is currently visible. When output to this console isn't possible all
  # output is routed to the default Kernel::puts method aliased as puts!.
  #
  #
  # Args:
  # - data:  Object, the object to output via the console or puts!.
  # - output_method:  Symbol, method to forward the data to. May be :puts! or
  #    :print!
  #
  def self.outputContent(output, metadata)

    obj = self.to_json(metadata)
    output = output.inspect

    unless @@rootConsole.nil? || !@@rootConsole.visible?
      @@rootConsole.execute_script(
        "try { console.appendContent(#{output}, #{obj})" +
        "} catch (e) { console.appendContent(e, {'type': 'error'}) };")
    end

  end


  # BEGIN PASTED
  # TODO: put these two methods somewhere where they fit well (Bridge?)
  # Make them private + instance methods (?)

  # Convert a json object into a Ruby hash.
  #
  # Args:
  # - json_string: String of a json object.
  #
  # Returns:
  # - Hash (or Array)
  def self.from_json(json_string)
    # Split at every even number of unescaped quotes; if it's not a string then replace : and null
    # DEBUG: test objects with empty strings "", test arrays, test pure strings, test strings with : or => or " or \
    ruby_string = json_string.split(/(\"(?:.*?[^\\])*?\")/).collect{|s| (s[0..0] != '"')? s.gsub(/\:/, "=>").gsub(/null/, "nil") : s }.join()
    result = eval(ruby_string)
    return result
    rescue Exception => e
      {}
  end

  # Convert a Ruby hash into a json string.
  #
  # Args:
  # - obj: Ruby object containing any of String, Symbol, Fixnum, Float, Array, Hash, TrueClass, FalseClass, NilClass.
  #
  # Returns:
  # - String of a json object, containing any of String, Fixnum, Float, Array, Object, true, false, null.
  def self.to_json(obj)
    # remove non-JSON objects
    return "null" unless [String, Symbol, Fixnum, Float, Array, Hash, TrueClass, FalseClass, NilClass].inject(false){|b,c| b = (obj.is_a?(c))? true : b}
    if obj.is_a? Array
      obj.reject!{|k| ![String, Symbol, Fixnum, Float, Array, Hash, TrueClass, FalseClass, NilClass].inject(false){|b,c| b = (k.is_a?(c))? true : b} }
    elsif obj.is_a? Hash
      obj.reject!{|k,v|
        !k.is_a?(String) && !k.is_a?(Symbol) ||
        ![String, Symbol, Fixnum, Float, Array, Hash, TrueClass, FalseClass, NilClass].inject(false){|b,c| b = (v.is_a?(c))? true : b}
      }
    end
    # split at every even number of unescaped quotes; if it's not a string then turn Symbols into String and replace => and nil
    json_string = obj.inspect.split(/(\"(?:.*?[^\\])*?\")/).collect{|s| (s[0..0] != '"')? s.gsub(/\:(\S+?(?=\=>|\s))/, "\"\\1\"").gsub(/=>/, ":").gsub(/\bnil\b/, "null") : s }.join()
    return json_string
  end
  # END

  # Log a message to a log file.
  #
  # Args:
  # - str: String, the message to log to a file.
  #
  def self.log(str="")
    path = Developer::Console.log_file
    timestamp = Developer::Console.timestamp? ? Time.now.to_s + ' ' : ''
    begin
      # Open is an 'append'. Clearing the log is a separate operation.
      open(path, 'a') do |f|
        f << timestamp + str.to_s + "\n"
      end
    rescue Exception => e
      puts! "#{e.class}: #{e.message}"
    end
  end

  # Sets the default "quiet" flag for all consoles. Individual consoles can
  # override this setting based on their configuration at execution time.
  # The quiet flag determines whether Kernel::puts output is discarded.
  #
  # Args:
  # - flag: Boolean, a value which should be true to activate quiet mode.
  #
  def self.quiet=(flag)
    quiet = (flag == true || flag == 'true')
    if (quiet != @@quiet)
      if (quiet)
        msg = 'Quiet mode ' + (quiet ? 'enabled. All puts statements are now being ignored.' : 'disabled.')
        puts $devl_strings.GetString(msg) unless @@nolog
        @@quiet = quiet
      else
        @@quiet = quiet
        msg = 'Quiet mode ' + (quiet ? 'enabled.' : 'disabled.')
        puts $devl_strings.GetString(msg) unless @@nolog
      end
    end
  end

  # Returns true if the console should discard Kernel::puts output.
  #
  #
  # Returns:
  # - flag: Boolean, true when quiet mode is active by default.
  #
  def self.quiet?
    return @@quiet == true
  end

  # Updates the default history list data. This method is typically called
  # from the history file itself during console initialization.
  #
  #
  # Args:
  # - data: Array, the array of history entries to set.
  #
  def self.setHistory(data=[])
    @@history = data
  end

  # Updates the configuration data for the Console. This method is
  # typically invoked by a config.rb file being loaded from the extention's
  # directory. Note that the items in the incoming Hash simply overlay those
  # in the default @@config property so the incoming data can be sparse.
  #
  #
  # Args:
  # - data:  Hash, A configuration hash containing items for @@config use.
  #
  def self.updateConfig(data)
    if !data.nil?
      data.each do |key, value|
        @@config[key] = value
      end
    end
  end

  # Initializes a new console. This is typically invoked in response to
  # activation via the SketchUp Tools->Developer->Console menu item. Note,
  # however, that the Console class overrides 'new' so that instances are
  # reused during a particular session.
  #
  #
  def initialize

    # Load the configuration from file if possible, so users can override
    # where the default console will appear etc. Since we do this with each
    # new instance initialization it's possible to update the configuration
    # before each new console creation.
    path = File.join(@@config[:toolroot], 'config.rb')
    if File.file?(path)
      load path
    end

    # Create a proc we can use as a shared context for eval calls.
    @binding = Proc.new {}

    # Make our own local copy of the class-level configuration data.
    @config = @@config.clone

    width = @config[:width]
    height = @config[:height]
    x = @config[:x]
    y =  @config[:y]

    # Assign a title. We'll look this up in the string table in a moment.
    title = 'Developer Console'

    # Create the dialog instance this console is managing.
    @dialog = UI::WebDialog.new($devl_strings.GetString(title),
      false, title, width, height, x, y, true)

    # Capture instances in a class-level list so we can reuse non-visible
    # ones. Note that the first instance in this list is the Root Console.
    @@instances.push(@dialog)
    if @@instances.length == 1
      @@rootConsole = @dialog
    end

    # Constrain to avoid clipping of toolbar and 3-5 lines of content.
    @dialog.min_height = @config[:minheight]
    @dialog.min_width = @config[:minwidth]

    # Load any stored history so it's available to the console instance.
    path = File.join(@@config[:toolroot], @config[:history])
    if File.file?(path)
      begin
        load path
      rescue Exception => e
        puts! "#{e.class}: #{e.message}"
      end
    end

    # Load any custom ruby overlays the user wants for customization.
    path = File.join(@@config[:toolroot], @config[:userrb])
    if File.file?(path)
      begin
        load path
      rescue Exception => e
        puts! "#{e.class}: #{e.message}"
      end
    end

    # Once we've loaded any custom extensions we can now add the action
    # callbacks which might include some defined by the user.
    self.methods.grep(/^do_/).each do |name|
      eval %{
        @dialog.add_action_callback("#{name}") { |d,p| #{name}(d,p) }
      }, nil, __FILE__, __LINE__
    end

    # Update configuration to have full paths for JS-relevant parameters. We
    # do this before showing the dialog so it's
    path = File.join(@@config[:toolroot], @config[:usercss])
    if File.file?(path)
      @config[:usercss] = path
    end
    path = File.join(@@config[:toolroot], @config[:userjs])
    if File.file?(path)
      @config[:userjs] = path
    end

    # Update paths for help file(s) we want to display.
    path = File.join(@@config[:toolroot], @config[:toolhelp])
    if File.file?(path)
      @config[:toolhelp] = path
    end

    # Show the dialog, making sure to use our method which will update the
    # dialog's file/url reference.
    self.show

  end

  # Responds to requests to clear the current log file. No query parameters
  # are necessary for this call.
  #
  #
  # Args:
  # - dialog: reference to the WebDialog that made the original request.
  # - query: the query string, the portion of a skp: URL after the @ sign.
  #
  def do_clear_log(dialog, query)
    params = Bridge.query_to_hash(dialog, query)
    Console.logging = params['logging']
    Console.quiet = params['quiet']

    path = Developer::Console.log_file
    begin
      open(path, 'w') do |f|
        f << ""
      end
      msg = $devl_strings.GetString('Log file cleared.')
      fault = false
    rescue Exception => e
      msg = "#{e.class}: #{e.message}"
      fault = true
    end

    puts msg
    Bridge.js_callback(dialog, 'do_exec', query, msg, fault)
  end

  # Responds to requests to execute a string of Ruby source code. This is the
  # core method driving the console's utility. The command to execute should
  # be placed in the query as 'command'. Additional parameters for 'logging'
  # and 'quiet' may be provided to define those flag values.
  #
  #
  # Args:
  # - dialog: reference to the WebDialog that made the original request.
  # - query: the query string, the portion of a skp: URL after the @ sign.
  #
  def do_exec(dialog, query)
    params = Bridge.query_to_hash(dialog, query)
    Console.logging = params['logging']
    Console.quiet = params['quiet']

    buffer = params['command']

    # Output the buffer/command string on the native console.
    puts!('> ' + buffer)
    # Send it to the log file.
    if Developer::Console.logging?
      Developer::Console.log('> ' + buffer)
    end

    begin
      # Note we do the eval here in the context of a reused proc. This
      # approach means that each call can build upon prior results and
      # variables which might have been created.
      result = eval(buffer, TOPLEVEL_BINDING)
      fault = false

      result = result.inspect
      Developer::Console.outputContent(result, {"type"=>"ruby result"})

    rescue Exception => e
      result = e.class.to_s + ': ' + e.message.to_s
      # When eval is called with TOPLEVEL_BINDING it's the first item in the
      # traceback that refer to the developer console. We omit this as it's
      # misleading.
      backtrace = e.backtrace[1..-1]
      # Send the error to the output:
      Developer::Console.outputContent(result, {"backtrace"=>backtrace, "type"=>"error"})
      fault = true
    end

    # Send it to the log file.
    if Developer::Console.logging?
      Developer::Console.log(result)
      Developer::Console.log(backtrace.join("\n")) if backtrace && !backtrace.empty?
    end

    result = Bridge.clean_for_xml(result)
    Bridge.js_callback(dialog, 'do_exec', query, result, fault) # TODO: What does this?
  end

  # Responds to requests to return the current configuration data. The
  # client JavaScript makes this request during initialization. There are no
  # specific query string parameters for this call.
  #
  #
  # Args:
  # - dialog: reference to the WebDialog that made the original request.
  # - query: the query string, the portion of a skp: URL after the @ sign.
  #
  def do_get_config(dialog, query)
    params = Bridge.query_to_hash(dialog, query)
    Console.logging = params['logging']
    Console.quiet = params['quiet']

    # TODO (idearat) Do we need to pre-process before sending as output?
    # Do a lightweight cleanse and conversion to simple JS object form.
    info = Bridge.clean_for_json(@config.inspect)
    info = '{' + info.gsub(/([{ ]):/, ' \'').gsub(/=>/,'\': ')

    Bridge.js_callback(dialog, 'do_get_config', query, info, false)
  end

  # Responds to requests to return any stored history list data. The
  # client JavaScript makes this request during initialization. There are no
  # specific query string parameters for this call.
  #
  #
  # Args:
  # - dialog: reference to the WebDialog that made the original request.
  # - query: the query string, the portion of a skp: URL after the @ sign.
  #
  def do_get_history(dialog, query)
    params = Bridge.query_to_hash(dialog, query)
    Console.logging = params['logging']
    Console.quiet = params['quiet']

    # Do a lightweight cleanse and send back to the requestor. Note the
    # replacement here which is necessary to get backslashes past the
    # response handler's requirement to eval the source.
    info = @@history.inspect
    info = info.gsub(/\\/, "\\\\\\\\")

    Bridge.js_callback(dialog, 'do_get_history', query, info, false)
  end

  # Responds to requests to update the default logging status. The new flag
  # value should be provided in the 'logging' query string parameter.
  #
  #
  # Args:
  # - dialog: reference to the WebDialog that made the original request.
  # - query: the query string, the portion of a skp: URL after the @ sign.
  #
  def do_logging(dialog, query)
    params = Bridge.query_to_hash(dialog, query)
    Console.logging = params['logging']
    Console.quiet = params['quiet']

    Bridge.js_callback(dialog, 'do_logging', query, Console.logging?.to_s,
        false)
  end

  # Responds to requests to update the default quiet-mode status. Quiet-mode
  # is when normal Kernel::puts output is discarded. The new quiet mode flag
  # value should be provided in the 'quiet' query string parameter.
  #
  #
  # Args:
  # - dialog: reference to the WebDialog that made the original request.
  # - query: the query string, the portion of a skp: URL after the @ sign.
  #
  def do_quiet(dialog, query)
    params = Bridge.query_to_hash(dialog, query)
    Console.logging = params['logging']
    Console.quiet = params['quiet']

    Bridge.js_callback(dialog, 'do_quiet', query, Console.quiet?.to_s, false)
  end

  # Responds to requests to reload some or all of the Ruby scripts found
  # within the Sketchup installation tree. Two filters are applied to the
  # scripts before they are reloaded. First, only scripts found in either
  # the plugins or tools directories are "eligible" for reloading. Second,
  # the @@config parameter :reload, which should be a regular expression, is
  # run to make sure the file matches the pattern found there. The 'quiet'
  # and 'logging' query string parameters may be provided to update those
  # flags prior to execution.
  #
  #
  # Args:
  # - dialog: reference to the WebDialog that made the original request.
  # - query: the query string, the portion of a skp: URL after the @ sign.
  #
  def do_reload(dialog, query)
    params = Bridge.query_to_hash(dialog, query)
    logging = Console.logging?
    Console.logging = params['logging']
    Console.quiet = params['quiet']

    # Search within our two folders.
    files = Dir[Sketchup.find_support_file('plugins') + '/*.rb']
    files.push Dir[Sketchup.find_support_file('tools') + '/*.rb']

    msgs = []
    fault = false
    prefix = $devl_strings.GetString('reloaded ')
    puts $devl_strings.GetString('Filtering reload via: ') +
        @config[:reload].to_s
    files.each do |path|
      next unless path =~ /[pP]lugins|[tT]ools/
      next unless path =~ @config[:reload]
      begin
        if load path
          msgs.push(prefix + path)
        end
      rescue Exception => e
         msgs.push("#{e.class}: #{e.message}")
         fault = true
      end
    end

    msg = msgs.join("\n")
    # Have to preserve logging state prior to actual reload since reload has
    # this tendency to reset things...like logging state...to off :).
    Console.nolog = true
    Console.logging = logging
    puts msg
    Console.logging = params['logging']
    Console.nolog = false

    msg = 'Reloaded ' + msgs.length.to_s + ' files.'
    Bridge.js_callback(dialog, 'do_reload', query, msg, fault)
  end

  # Responds to requests to save the current history list. The history
  # content to save is defined by the console making the request. The data
  # itself is stored to the file referenced in @config[:history] and should
  # be provided as the 'history' query string parameter.
  #
  #
  # Args:
  # - dialog: reference to the WebDialog that made the original request.
  # - query: the query string, the portion of a skp: URL after the @ sign.
  #
  def do_save_history(dialog, query)
    params = Bridge.query_to_hash(dialog, query)
    Console.logging = params['logging']
    Console.quiet = params['quiet']

    history = params['history']

    template = <<END
#!/usr/bin/ruby -w
#
# Stored history cache. This file is updated in response to explicit saves.
# Updating this file for use as a "common snippets" file is possible but it
# may be overwritten if you execute a save command from within the console.

END

    path = Developer::Console.history_file
    begin
      # Note we open for write here, completely removing any prior content.
      open(path, 'w') do |f|
        f << template + "Developer::Console.setHistory(\n#{history}\n)\n"
      end
      msg = $devl_strings.GetString('History cache updated.')
    rescue Exception => e
      msg = "#{e.class}: #{e.message}"
      puts! msg
    end

    puts msg

    Bridge.js_callback(dialog, 'do_save_history', query, msg, false)
  end

  # Shows overview help for the console.
  #
  #
  # Args:
  # - dialog: reference to the WebDialog that made the original request.
  # - query: the query string, the portion of a skp: URL after the @ sign.
  #
  def do_show_overview(dialog, query)
    url = @config[:toolhelp]
    UI.openURL(url)
    Bridge.js_callback(dialog, 'do_show_overview', query, url, false)
  end

  # Shows shortcut help for the console.
  #
  #
  # Args:
  # - dialog: reference to the WebDialog that made the original request.
  # - query: the query string, the portion of a skp: URL after the @ sign.
  #
  def do_show_shortcuts(dialog, query)
    msg = $devl_strings.GetString('shortcut_help');
    Bridge.js_callback(dialog, 'do_show_shortcuts', query, msg, false)
  end

  # Hides the receiver's internal web dialog control.
  #
  def hide
    @dialog.hide
  end

  # Returns true if the console's dialog is currently visible.
  #
  #
  # Returns:
  # - flag: Boolean, true if the console's dialog is currently visible.
  #
  def visible?
    @dialog.visible?
  end

  # Displays the receiver's internal web dialog after ensuring that it is
  # properly configured with the console markup URL to display.
  #
  def show
    # Note that __FILE__ here puts us in the 'ruby' subdirectory of the
    # extension so we pop up one level before dropping back down into the
    # html directory where the console markup can be found.
    @html = File.dirname(__FILE__) + '/../html/console.html'
    @dialog.set_file(@html, nil)
    @dialog.show
    @dialog.execute_script("document.getElementsByTagName('body')[0].style.background='"+@dialog.get_default_dialog_color+"'")

    # Catch ScriptErrors. Not a nice solution, but urgently needed.
    @last_error_id = $!.object_id
    # Since eval and $stderr (why?) don't catch script errors, we regularly look into the Ruby global $!
    @catch_script_error = Proc.new{
      if visible? && $!.object_id != @last_error_id
        Developer::Console.outputContent($!.to_s, {"type"=>"error", "backtrace"=>$@})
        @last_error_id = $!.object_id
      end
      UI.start_timer(0.1, false){@catch_script_error.call if visible?}
    }
    @catch_script_error.call
  end

end   # End of Console class

end   # End of DeveloperTools module


# Open the Kernel module so we can redefine 'puts' to route it to the
# console.
#
module Kernel

  # Protect against redefining this alias to an alias or bad things happen.
  if !defined? puts!

    # Capture the original version in an alias we can call in case of an
    # error in the console itself. Very useful for debugging.
    alias puts! puts
    alias print! print

    # Outputs data to the Developer Console, optionally discarding it when
    # in quiet mode, logging it to a file when logging is true, or routing
    # it to the original puts routine via the puts! alias when an error is
    # raised.
    #
    #
    # Args:
    # - output_method:  Symbol, method to forward the data to. May be :puts! or
    #    :print!
    # - args: Object, the object (usually a string) to output.
    #
    # TODO: do we need this method really?
    def puts_or_print(output_method, *args)
      # Regardless of whether we're in quiet mode or not we respect the
      # logging setting if set.
      if Developer::Console.logging?
        Developer::Console.log(*args) # TODO: support for print (or output_method)
      end

      if Developer::Console.quiet?
        # When quiet just discard and return.
        return
      else
        # TODO: @@rootConsole isn't defined in Kernel. This needs some work when
        # we transition to a subclass of Sketchup::Console instead of redefining puts.
        # If the developer console isn't active, fall-back to standard ruby output
        #if @@rootConsole.nil? || !@@rootConsole.visible?
          send(output_method, *args)
        #  return
        #end

        # Otherwise route to the console via our outputContent method.
        args.each{|arg|
          type = output_method.to_s.sub(/\!/,"") # TODO: improve this.
          Developer::Console.outputContent(arg.to_s, {"type"=>type})
        }
      end
    end

    # Replaces the original puts method to allow for re-routing the output
    # to appropriate locations.
    #
    #
    # Args:
    # - args: Object, the object (usually a string) to output.
    def puts(*args)
      puts_or_print(:puts!, *args)
      return
    end

    # Replaces the original print method to allow for re-routing the output
    # to appropriate locations.
    #
    #
    # Args:
    # - args: Object, the object (usually a string) to output.
    def print(*args)
      puts_or_print(:print!, *args)
      return
    end

  end

end   # End of Kernel module
