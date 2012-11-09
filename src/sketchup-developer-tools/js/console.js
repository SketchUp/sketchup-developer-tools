//  Copyright 2012 Trimble Navigation Ltd.

/**
 * @fileoverview A WebDialog-based console for SketchUp Ruby developers.
 * The JavaScript portion of the console communicates with a Ruby portion
 * to handle execution of Ruby, processing of reload and configuration
 * commands, etc.
 * @supported Note that the functionality in this file is intended to
 * support Sketchup's current use of embedded IE6+ and/or WebKit 2.0+
 * browsers only.
 */

//  --------------------------------------------------------------------------
//  Prerequisites
//  --------------------------------------------------------------------------

// Export the su namespace. See bridge.js for definition.
var su = window.su;

// Export the skp namespace. See bridge.js for definition.
var skp = window.skp;

/**
 * Console object used as a namespace/type rather than creating instance(s).
 * @type {Object}
 */
var console = {};

/**
 * The maximum font size we support in the console.
 * @type {number}
 */
console.CONTENT_MAXFONT = 36;

/**
 * The minimum font size we support in the console.
 * @type {number}
 */
console.CONTENT_MINFONT = 10;

/**
 * The default height of spacing above/below the input the text area. This
 * value is used for sizing computations in certain circumstances.
 * @type {number}
 */
console.TEXTAREA_CHROME = 19;

/**
 * The default line-height CSS value for the text area. This value is used
 * for sizing computations when we're unable to determine the line height
 * based on computed style data.
 * @type {number}
 */
console.TEXTAREA_LINEHEIGHT = 14;

/**
 * The list of commands which have been entered. This is a combination of
 * any data loaded from a persistent history cache file and any data entered
 * during the current session. The maximum size of this array is defined by
 * the historyMax variable.
 * @type {Array}
 * @private
 */
console.history_ = [];

/**
 * The current index into the history list. The Shift-Up and Shift-Down
 * arrow key combinations adjust this value at runtime to drive history
 * entry display.
 * @type {number}
 * @private
 */
console.historyIndex_ = 0;

/**
 * The maximum number of entries stored in the history list.
 * @type {number}
 */
console.historyMax = 50;

/**
 * Is the reverse-video "theme" currently activated?
 * @type {Boolean}
 * @private
 */
console.invert_ = false;

/**
 * Is logging to the console log file currently turned on?
 * @type {Boolean}
 * @private
 */
console.logging_ = false;

/**
 * Is plain output mode currently active?
 * @type {Boolean}
 * @private
 */
console.plain_ = false;

/**
 * Is quiet mode currently active?
 * @type {Boolean}
 * @private
 */
console.quiet_ = false;

/**
 * Is the shift key required for execution (as in Shift-Enter vs. Enter)?
 * @type {Boolean}
 * @private
 */
console.shiftexec_ = false;

//  --------------------------------------------------------------------------
//  Initialization
//  --------------------------------------------------------------------------

/**
 * Initialize the console, ensuring the proper event listeners and other
 * infrastructure elements are in place and ready for user activity.
 */
console.initialize = function() {

  // Install key handlers at the document level. We can then determine
  // whether they're shortcuts or should be routed to the command cell.
  su.installHandler(document.documentElement, 'keydown',
    console.handleKeyDown);
  su.installHandler(document.documentElement, 'keypress',
    console.handleKeyPress);
  su.installHandler(document.documentElement, 'keyup', console.handleKeyUp);

  // To ensure we have complete control we'll install the same handlers
  // explicitly at the command cell level. We use this in at least one case
  // to stop Escape from closing the window when the cell is focused.
  su.installHandler($('command'), 'keydown', console.handleKeyDown);
  su.installHandler($('command'), 'keypress', console.handleKeyPress);
  su.installHandler($('command'), 'keyup', console.handleKeyUp);

  // Install cut/paste handlers on the input cell so we can resize. Note
  // that we have to use async handlers here so the text reflow is done
  // before we try to capture the value for resizing.
  su.installHandler($('command'), 'cut', console.resizeCommandCellAsync);
  su.installHandler($('command'), 'paste', console.resizeCommandCellAsync);

  // Click handlers for the toolbar elements.
  su.installHandler($('clear'), 'click', console.clearContent);
  su.installHandler($('reload'), 'click', console.reloadRubyScripts);

  if (su.IS_MAC) {
    su.installHandler($('logged'), 'click', console.toggleLogging);
    su.installHandler($('quiet'), 'click', console.toggleQuiet);
    /*su.installHandler($('plain'), 'click', console.togglePlain);*/
  } else {
    su.installHandler($('logged_check'), 'click', console.toggleLogging);
    su.installHandler($('quiet_check'), 'click', console.toggleQuiet);
    /*su.installHandler($('plain_check'), 'click', console.togglePlain);*/
  }

  su.installHandler($('invert'), 'click', console.toggleColorScheme);
  su.installHandler($('smaller'), 'click', console.decreaseContentFont);
  su.installHandler($('larger'), 'click', console.increaseContentFont);
  //su.installHandler($('help'), 'click', console.displayHelp);

  su.installHandler($('go'), 'click', console.execCommandCell);

  // Retrieve configuration dictionary data. On completion this handler will
  // trigger retrieval of history data as well.
  su.callRuby('do_get_config',
      {'oncomplete': 'console.handleGetConfigComplete'});
};

//  --------------------------------------------------------------------------
//  Built-in Commands
//  --------------------------------------------------------------------------

/**
 * Executes a clear command, clearing the console, log, or history list
 * based on the optional target provided. When no target is present the
 * console is cleared.
 * @param {string} opt_target The target, either 'history', 'log',
 *     'content', 'console', or an empty or null value.
 */
console.exec_clear = function(opt_target) {

  // Default our target to the content of the console when not specified.
  var target = su.notEmpty(opt_target) ? opt_target.toLowerCase() : 'content';

  // We offer a couple of choices here. Clearing history, the log file, or
  // the console.
  switch (target) {
    case 'history':
      console.history_ = [];
      su.callRuby('do_save_history', {
        'logging': console.logging_,
        'quiet': console.quiet_
      });
      break;
    case 'log':
      su.callRuby('do_clear_log', {
        'logging': console.logging_,
        'quiet': console.quiet_
      });
      break;
    case 'content':
    case 'console':
      console.clearContent();
      break;
    default:
      console.appendContent('Unknown target for clear: ' + opt_target);
      break;
  }
};

/**
 * Alias in short form for the clear command.
 * @type {Function}
 */
console.exec_c = console.exec_clear;

/**
 * Executes the help command, displaying help documentation.
 */
console.exec_help = function() {
  console.displayHelp();
};

/**
 * Alias in short form for the help command.
 * @type {Function}
 */
console.exec_h = console.exec_help;

/**
 * Executes the "javascript" command, evaluating any string after the
 * initial command text itself as a string of JavaScript source code.
 * @param {string} script The string to evaluate.
 */
console.exec_js = function(script) {
  var type = "javascript";
  try {
    result = window.eval(script);
    result = String(result); // or better IE8+ JSON.stringify(result);
    type += " result";
  } catch (e) {
    result = e.message;
    type += " error";
  }

  console.appendContent(result, {'type': type});
};

/**
 * Executes the reload command, reloading Ruby scripts which are found
 * within the plugins or tools directory which match the :reload filter
 * provided in the config.rb file or in the default configuration. Normally
 * only scripts in the plugin directory pass this second filter.
 */
console.exec_reload = function() {
  console.reloadRubyScripts();
};

/**
 * Alias in short form for the reload command.
 * @type {Function}
 */
console.exec_r = console.exec_reload;

/**
 * Executes the save command, saving the current console history list to the
 * :history file name. By default this is history.rb in tools/Developer/etc.
 */
console.exec_save = function() {
  console.saveHistory();
};

/**
 * Executes the shortcuts command, displaying simple command line help, in
 * particular help on the set of exec_* commands which are documented.
 */
console.exec_shortcuts = function() {
  console.displayShortcuts();
};

//  --------------------------------------------------------------------------
//  Command Cell
//  --------------------------------------------------------------------------

/**
 * Clears the command input text cell.
 */
console.clearCommandCell = function() {
  var textarea = $('command');
  textarea.value = '';
  console.resizeCommandCell();
  textarea.focus();
};

/**
 * Executes the text found in the command input text cell. Command input
 * which starts with a \ is treated as a console command rather than Ruby
 * source code.
 */
console.execCommandCell = function() {

  var textarea = $('command');
  var command = textarea.value;

  // Trim off any extra formatting the browser may have added to "help".
  var cmd = su.trimWhitespace(command);
  if (su.isEmpty(cmd)) {
    console.resizeCommandCell();
    textarea.focus();
    return;
  }

  // Keep track of commands for a simple history feature.
  console.history_.push(cmd);
  console.historyIndex_ = console.history_.length;

  // Trim history to keep within max size specification.
  if (console.history_.length > console.historymax_) {
    console.history_.shift();
  }

  // Anything starting with a \ is a command line, not an eval buffer.
  if (cmd.indexOf('\\') == 0) {
    console.appendContent(cmd, {'type': 'command input'});
    var parts = cmd.slice(1).split(' ');
    cmd = parts[0];
    var fname = 'exec_' + cmd;
    if (typeof(console[fname]) == 'function') {
      console[fname](parts.slice(1).join(' '));
      console.clearCommandCell();
    } else if (cmd == '?') {
      // Special case here since exec_? isn't a valid JS identifier.
      console.exec_shortcuts();
      console.clearCommandCell();
    } else {
      console.appendContent('Unrecognized \\ command: ' + cmd);
      // Note that we don't clear bad commands, we let them be edited.
    }
    return;
  }

  // Send the command to appendContent and let it handle all markup.
  console.appendContent(cmd, {'type': 'ruby input'});

  // Ask for the Ruby to be eval'd and the result logged/quiet as needed.
  su.callRuby('do_exec', {
    'command': cmd,
    'logging': console.logging_,
    'quiet': console.quiet_
  });

  console.clearCommandCell();
};

/**
 * Resizes the input command cell after forking so that any pending reflow
 * can occur before attempting to compute cell height.
 */
console.resizeCommandCellAsync = function() {
  window.setTimeout(console.resizeCommandCell, 0);
};

/**
 * Resizes the command cell adjusting its height for multi-line input text.
 * The height computation is largely driven off computed values but two
 * default values, console.TEXTAREA_LINEHEIGHT and console.TEXTAREA_CHROME,
 * may also be used to manage cell height.
 */
console.resizeCommandCell = function() {
  var textarea = $('command');
  var max = su.elementGetBorderBox('content').height;

  if (su.IS_MAC) {
    // Downsize to force scrollHeight to tell us the right size for the
    // content without scrolling.
    textarea.style.height = '0px';
    var height = textarea.scrollHeight;
    textarea.style.height = 'auto';

    // Don't let height exceed content area size, and adjust overflow when we
    // have to truncate the height due to extra large input (from paste etc).
    height = height + console.TEXTAREA_CHROME;
    height = Math.min(height, max);
    height = Math.max(height, console.TEXTAREA_LINEHEIGHT +
        console.TEXTAREA_CHROME);
    if (height == max) {
      textarea.style.overflow = 'auto';
    } else {
      textarea.style.overflow = 'hidden';
    }
  } else {
    var rows = textarea.value.split('\n').length;
    textarea.setAttribute('rows', rows);
    height = su.elementGetBorderBox(textarea).height +
          console.TEXTAREA_CHROME - 4;

    // We run into a problem when the row count would put the textarea at a
    // size larger than our "max size" so at that point we have to roll back
    // the row count and turn on scrolling.
    textarea.style.overflow = 'hidden';
    var currentHeight = height;
    while ((height > max) && (rows > 0)) {
      rows -= 1;
      textarea.setAttribute('rows', rows);
      height = su.elementGetBorderBox(textarea).height +
          console.TEXTAREA_CHROME - 4;
      if (height == currentHeight) {
        break;
      }
      textarea.style.overflow = 'scroll';
    }
  }

  // Update the containing footer height and the textarea will update its
  // size based on our CSS height settings.
  var footer = $('footer');
  footer.style.height = height + 'px';

  return;
};

/**
 * Sets the value of the command cell to a string value. This is typically
 * called by the history commands to insert a history entry into the command
 * line.
 * @param {string} aValue The new command line text.
 */
console.updateCommandCell = function(aValue) {
  var textarea = $('command');
  textarea.value = aValue;
  console.resizeCommandCell();
  textarea.focus();
};

//  --------------------------------------------------------------------------
//  Console Content
//  --------------------------------------------------------------------------

/**
 * Appends content to the console and adds markup depending on message type.
 * @param {string} output The new output content to append.
 */
console.appendContent = function(output, metadata) {
  var content = $('content');
  var str = su.trimWhitespace(content.innerHTML);
  metadata = metadata || {};
  var type = metadata['type'] || 'other';

  // We do all xml markup only here:
  // Prepare all <,> for xml, except if the syntax highlighter does it for us.
  if ( !/ruby/.test(type) ) {
    output = output.replace(/\</g, '&lt;').replace(/\>/g, '&gt;')
  };

  // Handle different message types.
  // Errors
  if ( /error/.test(type) ) {
    var backtrace = metadata['backtrace'] || [];
    backtrace = backtrace.join('<br>');
    // Shorten long file paths to make it easier to read.
    backtrace = backtrace.replace(/((?:[A-Z]\:|\/)[^\:]+)/g, function(filepath){
	    // Truncate the Plugins folder, or as fallback keep only the filename.
      var relpath = /\/[Pp]lugins\//.test(filepath)? filepath.replace(/^.*\/[Pp]lugins\//,"") : filepath.match(/[^\/]+$/);
      if(relpath == filepath){ return filepath };
      var truncated = '<a onclick="this.innerHTML=(this.innerHTML!=\'…\')? \'…\' : \'' + filepath.replace("/"+relpath,"") + '\'">…</a>/';
      return '<span class="filepath" title="' + filepath + '">' + truncated + relpath + '</span>';
    });

    str += '<div class="message ' + type + ' ui-collapsible-panel collapsed">' +
      '<div class="ui-collapsible-header" ' +
      'onclick="console.toggleClass(this.parentNode, \'collapsed\')" >' +
      output + '</div>' +
      '<div class="ui-collapsible-content">' + backtrace + '</div>' +
      '</div>';
  }
  // Print
  else if ( /print|puts/.test(type) ) {
    if ( /ruby/.test(type) && su.isDefined(hljs) ) {
      output = '<pre><code>' + hljs.highlight('ruby', output).value + '</code></pre>'
    };
    str += '<span class="message ' + type + '">' + output + '</span>';
    // Except of print, everything else creates a new line after it.
    if ( !/print/.test(type) ) {str += '<br/>' };
  }
  // Anything else.
  else {
	  // Highlight Ruby code.
    if ( /ruby/.test(type) && su.isDefined(hljs) ) {
      output = '<pre><code>' + hljs.highlight('ruby', output).value + '</code></pre>';
    };
    str += '<div class="message ' + type + '">' + output + '</div>';
  }

  // Append to the console content.
  content.innerHTML = str;
  setTimeout(function() {
    su.scrollToEnd(content);
    }, 0);
};


// TODO: Place this function somewhere where it fits well.
/**
 * Toggles a class on an HTMLElement.
 */
console.toggleClass = function(element, className, value) {
  var r = new RegExp("(^\\s*|\\s*\\b)" + className + "(\\b|$)");
  if (value==null) { var value = !r.test(element.className) };
  if (value) {
    element.className += (element.className ? ' ' : '') + className;
  }
  else {
    element.className = element.className.replace(r, "");
  };
};


/**
 * Clears the console's content area.
 */
console.clearContent = function() {
  $('content').innerHTML = '';
};

/**
 * Decreases the current CSS font size for the content area by 2px and
 * adjusts the line-height to stay compatible with the new font size.
 */
console.decreaseContentFont = function() {
  var style = su.getComputedStyle('content');
  var size = parseFloat(style.fontSize);

  // Adjust both font-size and line-height to keep things looking proper.
  $('content').style.fontSize =
      Math.max(console.CONTENT_MINFONT, size - 2) + 'px';
  $('content').style.lineHeight =
      Math.max(console.CONTENT_MINFONT, size + 1) + 'px';
};

/**
 * Increases the current CSS font size for the content area by 2px and
 * adjusts the line-height to stay compatible with the new font size.
 */
console.increaseContentFont = function() {
  var style = su.getComputedStyle('content');
  var size = parseFloat(style.fontSize);

  // Adjust both font-size and line-height to keep things looking proper.
  $('content').style.fontSize =
      Math.min(console.CONTENT_MAXFONT, size + 2) + 'px';
  $('content').style.lineHeight =
      Math.min(console.CONTENT_MAXFONT, size + 5) + 'px';
};

/**
 * Sets the content of the console (clearing it of any prior content).
 * @param {string} The content to set in the console.
 */
console.setContent = function(output, metadata) {
  // Clear the content.
  var content = $('content').innerHTML = "";
  // Send the new content to appendContent.
  console.appendContent(output, metadata)
};

//  --------------------------------------------------------------------------
//  History
//  --------------------------------------------------------------------------

/**
 * Updates the command cell to display the previous history entry relative
 * to the current history index.
 */
console.historyBack = function() {

  console.historyIndex_ = Math.max(0, console.historyIndex_ - 1);

  var history = console.history_[console.historyIndex_];
  if (!su.isValid(history)) {
    return;
  }

  console.updateCommandCell(history);
};

/**
 * Updates the command cell to display the next history entry relative to
 * the current history index.
 */
console.historyNext = function() {
  console.historyIndex_ = Math.min(console.history_.length - 1,
      console.historyIndex_ + 1);

  var history = console.history_[console.historyIndex_];
  if (!su.isValid(history)) {
    return;
  }

  console.updateCommandCell(history);
};

/**
 * Loads cached history data into the current console, replacing any current
 * history which might be in place.
 */
console.loadHistory = function() {
  su.callRuby('do_get_history', {
    'logging': console.logging_,
    'quiet': console.quiet_,
    'oncomplete': 'console.handleGetHistoryComplete'
  });
};

/**
 * Saves the current console history list to the history cache file,
 * normally defined by :history as history.rb in tools/Developer/etc.
 */
console.saveHistory = function() {
  var entry;
  var arr = [];
  var len = console.history_.length;
  for (var i = 0; i < len; i++) {
    entry = console.history_[i];
    entry = entry.replace(/^\\/, '\\\\');
    entry = entry.replace(/([^\\])'/g, "$1\\'");
    arr.push("'" + entry + "'");
  }
  su.callRuby('do_save_history', {
    'history': '[' + arr.join(', ') + ']',
    'logging': console.logging_,
    'quiet': console.quiet_
  });
};

//  --------------------------------------------------------------------------
//  STDIO
//  --------------------------------------------------------------------------

/**
 * Toggles logging of console output to a file. The log file itself is
 * configured using commands available via the leading \ operator.
 * @param {Event} evt The native click event.
 */
console.toggleLogging = function(evt) {
  var check = $('logged_check');
  if (su.getEventTarget(evt) != check) {
    check.checked = !check.checked;
  }
  console.logging_ = check.checked;
  su.callRuby('do_logging', {
    'logging': console.logging_,
    'quiet': console.quiet_
  });
};

/**
 * Toggles display of plain or enhanced output to the console. By default
 * the console uses a delimited format which makes it easier to track
 * commands and their output but harder to copy raw blocks of output.
 * @param {Event} evt The native click event.
 */
console.togglePlain = function(evt) {
  var check = $('plain_check');
  if (su.getEventTarget(evt) != check) {
    check.checked = !check.checked;
  }
  console.plain_ = check.checked;

  if (check.checked) {
    su.addClass('content', 'plain');
  } else {
    su.removeClass('content', 'plain');
  }

  return;
};

/**
 * Toggles output production. When suspend is true any output that would
 * have otherwise been routed from Kernel::puts calls is simply discarded.
 * This can be useful when trying to keep output overhead down.
 * @param {Event} evt The native click event.
 */
console.toggleQuiet = function(evt) {
  var check = $('quiet_check');
  if (su.getEventTarget(evt) != check) {
    check.checked = !check.checked;
  }
  console.quiet_ = check.checked;
  su.callRuby('do_quiet', {
    'logging': console.logging_,
    'quiet': console.quiet_
  });
};

//  --------------------------------------------------------------------------
//  Commands/Toolbar
//  --------------------------------------------------------------------------

/**
 * Executes the help command, displaying help documentation.
 */
console.displayHelp = function() {
  su.callRuby('do_show_overview');
};

/**
 * Executes the shortcuts command, displaying simple command line help, in
 * particular help on the set of exec_* commands which are documented.
 */
console.displayShortcuts = function() {
  su.callRuby('do_show_shortcuts', {
    'oncomplete': 'console.handleDisplayShortcutsComplete'
  });
};

/**
 * Executes the reload command, reloading Ruby scripts which are found
 * within the plugins or tools directory which match the :reload filter
 * provided in the config.rb file or in the default configuration. Normally
 * only scripts in the plugin directory pass this second filter.
 */
console.reloadRubyScripts = function() {
  su.callRuby('do_reload', {
    'logging': console.logging_,
    'quiet': console.quiet_
  });
};

/**
 * Toggles the color scheme from dark-on-light to light-on-dark or the
 * inverse, turning on or off "reverse video" mode. The specific display is
 * driven by CSS styles relative to the "reverse" class found on the content
 * container in the console's markup.
 * @param {Event} evt The native click event.
 */
console.toggleColorScheme = function(evt) {
  var elem = $('invert');
  if (su.notValid(elem)) {
    return;
  }
  var current = elem.getAttribute('class') || elem.className;
  if (current == 'reverse') {
    console.invert_ = false;
    su.removeClass(elem, 'reverse');
    su.removeClass('content', 'reverse');
  } else {
    console.invert_ = true;
    su.addClass(elem, 'reverse');
    su.addClass('content', 'reverse');
  }

  return;
};

//  --------------------------------------------------------------------------
//  Handlers
//  --------------------------------------------------------------------------

/**
 * Responds to notifications from the Ruby-JS bridge that a do_show_shortcuts
 * call has completed. The response data should be HTML for display.
 * @param {string} queryid The unique request ID used for the bridge call.
 */
console.handleDisplayShortcutsComplete = function(queryid) {
  var response = su.getRubyResponse(queryid);
  if (su.notValid(response) || (typeof response == 'string')) {
    console.appendContent('Unable to read configuration data: ' + response);
    return;
  }
  console.append(response);
};

/**
 * Responds to notifications from the Ruby-JS bridge that a do_get_config
 * call has completed. If configuration data was successfully read this
 * command will update the current instance's configuration data properly.
 * @param {string} queryid The unique request ID used for the bridge call.
 */
console.handleGetConfigComplete = function(queryid) {
  var response = su.getRubyResponse(queryid);
  if (su.notValid(response) || (typeof response == 'string')) {
    console.appendContent('Unable to read configuration data: ' + response);
    return;
  }
  console.config = response;

  if (console.config) {
    // Toggle the color scheme. Because we'll call toggle to do most of the
    // work here we actually set the value inverted from what we want to end
    // up with and the toggle will take it from there.
    if (console.config.inverse) {
      $('invert').removeAttribute('class');
      $('invert').className = '';
    } else {
      $('invert').setAttribute('class', 'reverse');
      $('invert').className = 'reverse';
    }
    console.toggleColorScheme();

    // Update Shift-Enter vs. Enter preference if set.
    if (su.isValid(console.config.shiftexec)) {
      console.shiftexec_ = console.config.shiftexec;
    }

    // Update maximum history size if found.
    if (su.isValid(console.config.historymax)) {
      console.historymax_ = console.config.historymax;
    }

    // Load any user-specific CSS overlay for customization.
    if (console.config.usercss) {
      su.addStylesheet(document, console.config.usercss);
    }

    // Load any user-specific JavaScript overlay for customization.
    if (console.config.userjs) {
      var node = document.createElement('script');
      node.setAttribute('src', console.config.userjs);
      try {
        document.getElementsByTagName('head')[0].appendChild(node);
      } catch (e) {
        console.appendContent('Unable to process user script: ' +
            console.config.userjs);
      }
    }
  }

  // Once we've got our configuration data loaded we can load history.
  su.callRuby('do_get_history',
      {'oncomplete': 'console.handleGetHistoryComplete'});
};


/**
 * Returns the position of the user's text cursor.
 * @param {HTMLElement} node The textarea we're interested in.
 * @return {number} The position of the cursor.
 */
console.getCaretPosition = function(node) {
  if (node.selectionStart) {
    return node.selectionStart;
  } else if (!document.selection) {
    return 0;
  }

  var c = "\001",
  sel = document.selection.createRange(),
  dul = sel.duplicate(),
  len = 0;

  dul.moveToElementText(node);
  sel.text = c;
  len = dul.text.indexOf(c);
  sel.moveStart('character',-1);
  sel.text = "";
  return len + 1;
};


/**
 * Responds to notifications that a keydown event has occurred. Key down
 * events are used to process navigation keys that we don't want to end up in
 * the target field such as Tab and Return.
 * @param {Event} evt The native keydown event.
 * @param {number} opt_manualKeycode An optional alternative keycode to force.
 * @return {boolean} True so the event default operation continues.
 */
console.handleKeyDown = function(evt, opt_manualKeycode) {

  var keycode = su.ifInvalid(opt_manualKeycode, su.getKeyCode(evt));

  // Note that we handle arrow keys in the down handler since that's the
  // only handler that gets the keycode correctly disambiguated from the &
  // and ( keys.
  switch (keycode) {
    case su.ESCAPE_KEY:
      // Trap Esc before it causes the dialog window to close.
      su.preventDefault(evt);
      su.stopPropagation(evt);
      return true;
    case su.ARROW_UP_KEY:
      var caretPosition = console.getCaretPosition($('command'));
      var parts = $('command').value.split(/\n/);
      var isFirstLine = false;
      if (caretPosition <= parts[0].length) {
        isFirstLine = true;
      }
      // Note that IE reports strange caret positions for empty textareas,
      // as well as negative ones for end of string, so handle those cases.
      if ((isFirstLine && caretPosition > 0) || parts.length == 1) {
        su.preventDefault(evt);
        su.stopPropagation(evt);
        console.historyBack();
        return;
      }
      break;
      
    case su.ARROW_DOWN_KEY:
      var caretPosition = console.getCaretPosition($('command'));
      var parts = $('command').value.split(/\n/);
      var isLastLine = false;
      var lastLineStart = parts.join("\n").length -
          parts[parts.length - 1].length;
      // Note that IE reports negative caret position at the end
      // of the string, so handle that as a special case.
      if (caretPosition >= lastLineStart || caretPosition <= 0) {
        isLastLine = true;
      }
      if (isLastLine) {
        su.preventDefault(evt);
        su.stopPropagation(evt);
        console.historyNext();
        return;
      }
      break;
    case su.ENTER_KEY:
      if (console.shiftexec_ && su.getShiftKey(evt)) {
        su.preventDefault(evt);
        su.stopPropagation(evt);
        console.execCommandCell();
        return;
      } else if (!console.shiftexec_ && !su.getShiftKey(evt)) {
        su.preventDefault(evt);
        su.stopPropagation(evt);
        console.execCommandCell();
        return;
      }
      break;
    default:
      // Make the console command line work like the VCB, any key that you
      // type other than an attempt to use a Ctrl-* combination will focus
      // the command line to focus.
      if (!su.getCtrlKey(evt)) {
        $('command').focus();
      }
      break;
  }
};

/**
 * Responds to notifications that a keypress event has occurred. For fields
 * ignore these events for any of the navigation keys to ensure they don't
 * affect field content.
 * @param {Event} evt The native keypress event.
 * @param {number} opt_manualKeycode An optional alternative keycode to force.
 * @return {boolean} True so the event default operation continues.
 */
console.handleKeyPress = function(evt, opt_manualKeycode) {
  var keycode = su.ifInvalid(opt_manualKeycode, su.getKeyCode(evt));

  switch (keycode) {
    case su.ESCAPE_KEY:
      // Trap Esc before it causes the dialog window to close.
      su.preventDefault(evt);
      su.stopPropagation(evt);
      return true;
    default:
      break;
  }

  return true;
};

/**
 * Responds to notifications that a keyup event has occurred.
 * @param {Event} evt The native keyup event.
 * @param {number} opt_manualKeycode An optional alternative keycode to force.
 * @return {boolean} True so the event default operation continues.
 */
console.handleKeyUp = function(evt, opt_manualKeycode) {
  console.resizeCommandCellAsync();
  return true;
};

/**
 * Responds to notifications that a do_get_history call has completed. If
 * history data was successfully read then this command will update the
 * console's history list accordingly.
 * @param {string} queryid The unique request ID used for the bridge call.
 */
console.handleGetHistoryComplete = function(queryid) {
  var response = su.getRubyResponse(queryid);
  if (su.notValid(response) || (typeof response == 'string')) {
    console.appendContent('Unable to read history data: ' + response);
    return;
  }

  console.history_ = response;
  console.historyIndex_ = response.length;

  // Trim history to keep within max size specification.
  while (console.history_.length > console.historymax_) {
    console.history_.shift();
  }
};

//  --------------------------------------------------------------------------
//  Helpers
//  --------------------------------------------------------------------------

/**
 * Installs a handler for an event in a cross-browser (IE/WebKit) fashion.
 * @param {Element} target The target object to install the handler on.
 * @param {string} eventName The event name without a leading 'on' prefix.
 * @param {Function} handler The function used to respond to events.
 */
su.installHandler = function(target, eventName, handler) {
  var name = eventName.toLowerCase().replace(/^on/, '');

  if (su.IS_MAC) {
    target.addEventListener(name, handler, true);
  } else {
    target.attachEvent('on' + name, handler);
  }
};

/**
 * Returns the Control Key from the event provided, or the current window
 * event when no event is specified.
 * @param {Event} opt_evt The native event.
 * @return {Element} The event target.
 */
su.getCtrlKey = function(opt_evt) {
  var ev = opt_evt || window.event;

  return ev.ctrlKey;
};

/**
 * Returns the target from the event provided, or the current window event
 * when no event is specified.
 * @param {Event} opt_evt The native event.
 * @return {Element} The event target.
 */
su.getEventTarget = function(opt_evt) {
  var ev = opt_evt || window.event;

  return ev.target || ev.srcElement;
};

/**
 * Adds a CSS class name to an element, ensuring it is only present once.
 * @param {string|Element} elementOrId The element or element ID to find.
 * @param {string} className The class name to remove.
 */
su.addClass = function(elementOrId, className) {
  var elem = $(elementOrId);
  if (su.notValid(elem)) {
    return;
  }

  var classes = su.ifInvalid(elem.getAttribute('class'), '');
  var parts = classes.split(' ');
  for (var i = 0; i < parts.length; i++) {
    if (parts[i] == className) {
      return;
    }
  }

  var str = su.trimWhitespace(classes + ' ' + className);
  elem.setAttribute('class', str);
  elem.className = str;
};

/**
 * Removes a CSS class from an element.
 * @param {string|Element} elementOrId The element or element ID to find.
 * @param {string} className The class name to remove.
 */
su.removeClass = function(elementOrId, className) {
  var elem = $(elementOrId);
  if (su.notValid(elem)) {
    return;
  }

  var classes = su.ifInvalid(elem.getAttribute('class'), '');
  var parts = classes.split(' ');
  for (var i = 0; i < parts.length; i++) {
    if (parts[i] == className) {
      parts[i] = '';
      break;
    }
  }

  var str = su.trimWhitespace(parts.join(' ').replace('  ', ' '));
  elem.setAttribute('class', str);
  elem.className = str;
};

/**
 * Scrolls an element to position the last of it's child content so that it
 * is visible.
 * @param {string|Element} elementOrId The element or element ID to find.
 */
su.scrollToEnd = function(elementOrId) {
  var elem = $(elementOrId);
  if (su.notValid(elem)) {
    return;
  }

  elem.scrollTop = elem.scrollHeight;
};

