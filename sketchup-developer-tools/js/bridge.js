//  Copyright 2012 Trimble Navigation Ltd.

/**
 * @fileoverview SketchUp-wide baseline routines for coordinating WebDialog
 * JavaScript logic with the SketchUp Ruby API.
 * @supported Note that the functionality in this file is intended to support
 * Sketchup's current use of embedded IE6+ and/or WebKit 2.0+ browsers only.
 */

//  --------------------------------------------------------------------------
//  Prerequisites
//  --------------------------------------------------------------------------

// Define the "SketchUp" object which holds our common utility functions
// and constants and serves as our public interface to these properties.

/**
 * The global sketchup utilities namespace, containing functions, properties,
 * and constants which are shared by sketchup web dialog consumers.
 * @type {Object}
 */
var su = {};

/**
 * The SketchUp "information dictionary", containing key/value pairs for data
 * elements such as version number, pro vs. free, etc.
 * @type {Object}
 */
su.info = {};

/**
 * The current version number of the SketchUp Ruby/JavaScript bridge logic.
 * @type {number}
 */
su.BRIDGE_VERSION = 1.0;

/**
 * Whether we are running on the Macintosh platform or not.
 * @type {boolean}
 */
su.IS_MAC = (navigator.appVersion.indexOf('Mac') != -1) ? true : false;

// Safari doesn't track activeElement, so patch that in for compatibility
// with IE by hooking the focus event.
(function() {
  var func;
  if (!window.attachEvent) {
    document.addEventListener('focus', function(evt) {
      document.activeElement = evt.target;
    }, true);
  }
}());

/**
 * Declare W3C properties for jscompiler.
 */
var CSSPrimitiveValue;

/**
 * W3C-standard DOM object containing encodings for the various node types.
 * Older versions of IE don't have the Node object or W3C DOM constants
 * per http://www.w3.org/TR/DOM-Level-3-Core/ecma-script-binding.html
 * @type {Object}
 */
window.Node = window.Node || {
  ELEMENT_NODE: 1,
  ATTRIBUTE_NODE: 2,
  TEXT_NODE: 3,
  CDATA_SECTION_NODE: 4,
  ENTITY_REFERENCE_NODE: 5,
  ENTITY_NODE: 6,
  PROCESSING_INSTRUCTION_NODE: 7,
  COMMENT_NODE: 8,
  DOCUMENT_NODE: 9,
  DOCUMENT_TYPE_NODE: 10,
  DOCUMENT_FRAGMENT_NODE: 11,
  NOTATION_NODE: 12
};

/**
 * Keycode for a standard Down Arrow key on US keyboards.
 * @type {number}
 */
su.ARROW_DOWN_KEY = 40;

/**
 * Keycode for a standard Up Arrow key on US keyboards.
 * @type {number}
 */
su.ARROW_UP_KEY = 38;

/**
 * Keycode for backspace key on US keyboards.
 */
su.BACKSPACE_KEY = 8;

/**
 * Keycode for delete key on US keyboards.
 */
su.DELETE_KEY = 46;

/**
 * Keycode for a standard Return/Enter key on US keyboards.
 * @type {number}
 */
su.ENTER_KEY = 13;

/**
 * Keycode for a standard Escape key on US keyboards.
 * @type {number}
 */
su.ESCAPE_KEY = 27;

/**
 * Keycode for a standard Shift key on US keyboards.
 * @type {number}
 */
su.SHIFT_KEY = 16;

/**
 * Keycode for a standard Tab key on US keyboards.
 * @type {number}
 */
su.TAB_KEY = 9;

/**
 * Returns the element whose ID is given. If the parameter is an element it
 * is returned unchanged. This routine will also check the element's name
 * attribute if no element with the given ID is provided.
 * @param {string|Element} elementOrID The element or element ID to find.
 * @param {Element} opt_root An optional element to root the query at.
 * @return {Element?} The targeted Element.
 */
function $(elementOrID, opt_root) {
  if (su.notValid(elementOrID)) {
    su.raise(su.translateString('Invalid parameter.'));
    return;
  }

  if (su.isString(elementOrID)) {
    var el = document.getElementById(elementOrID);
    if (su.isValid(el)) {
      if (su.isValid(opt_root)) {
        if (su.elementHasParent(el, opt_root)) {
          return el;
        }
      } else {
        return el;
      }
    }
    var list = document.getElementsByTagName('*');
    var len = list.length;
    for (var i = 0; i < len; i++) {
      el = list[i];

      // Note that IE will include comment nodes in '*' queries so we filter
      // for that here.
      if (el.nodeType != Node.ELEMENT_NODE) {
        continue;
      }

      if (el.getAttribute('name') == elementOrID) {
        if (su.isValid(opt_root)) {
          if (su.elementHasParent(el, opt_root)) {
            return el;
          }
        } else {
          return el;
        }
      }
    }
  } else if (elementOrID.nodeType == Node.ELEMENT_NODE) {
    return elementOrID;
  } else {
    su.raise(su.translateString('Invalid parameter.'));
    return;
  }
}

/**
 * Pull as much SketchUp information as we can get and stores it into the
 * su.info dictionary.
 * @param {string} opt_completeCallback Optional name of a function to call
 *     once the pull_information is complete.
 */
su.init = function(opt_completeCallback) {
  su.callRuby('pull_information', {
    'onsuccess': 'su.handlePullInformationSuccess',
    'oncomplete': opt_completeCallback
  });
};

//  --------------------------------------------------------------------------
//  Friendly Wrappers
//  --------------------------------------------------------------------------

// These are the "public" methods that make consuming SketchUp data as simple
// as possible. su.init() must be called first, ideally in the page's onload
// event, so that the other details about the SketchUp model are available.

/**
 * The global sketchup namespace, containing functions, properties, and
 * constants which are shared by sketchup web dialog consumers.
 * @type {Object}
 */
var skp = {};

/**
 * A container for the active model entity's data.
 * @type {Object}
 */
skp.activeModel = {};

/**
 * A container for the active selection's data.
 * @type {Object}
 */
skp.activeModel.selection = {};

/**
 * A container for the active model's definitions data.
 * @type {Object}
 */
skp.activeModel.definitions = {};

/**
 * A container for the current dialog's data.
 * @type {Object}
 */
skp.dialog = {};

/**
 * Pull as much SketchUp information as we can get and stores it into the
 * su.info dictionary. This is a friendly wrapper to the su.init() function
 * so that end users of this file do not need to be familiar with the su
 * namespace.
 */
skp.init = function() {
  su.init();
};

/**
 * @return {string} The user's Sketchup platform/os.
 */
skp.platform = function() {
  if (su.IS_MAC) {
    return 'mac';
  } else {
    return 'windows';
  }
};

/**
 * @return {string} The user's Sketchup language.
 */
skp.language = function() {
  return su.info['language'];
};

/**
 * @return {string} The user's Sketchup version.
 */
skp.version = function() {
  return su.info['version'];
};

/**
 * @return {string} The user's default units.
 */
skp.units = function() {
  return su.info['units'];
};

/**
 * @return {string} The user's decimal delimiter.
 */
skp.decimalDelimiter = function() {
  return su.ifEmpty(su.info['decimal_delimiter'], '.');
};

/**
 * @return {boolean} Whether Sketchup is the pro version.
 */
skp.isPro = function() {
  return su.info['is_pro'];
};

/**
 * @return {number} The version of the dc code running on SketchUp.
 */
skp.dcVersion = function() {
  return su.info['dc_version'];
};

/**
 * @return {number} The version of the "bridge" code.
 */
skp.bridgeVersion = function() {
  return su.BRIDGE_VERSION;
};

/**
 * Tells SketchUp to open a webdialog having certain properties.
 * @param {string} name Name of the window to open, which will show in the
 *     title bar of the dialog.
 * @param {string} url Full url you'd like to open in the new dialog.
 * @param {number} opt_w Width of the new dialog, in pixels.
 * @param {number} opt_h Height of the new dialog, in pixels.
 * @param {number} opt_x The X or left of the new dialog, in pixels.
 * @param {number} opt_y The Y or top of the new dialog, in pixels.
 */
skp.openWebDialog = function(name, url, opt_w, opt_h, opt_x, opt_y) {
  su.callRuby('do_show_dialog', {
    'name': name,
    'url': url,
    'w': opt_w,
    'h': opt_h,
    'x': opt_x,
    'y': opt_y
  });
};

/**
 * Tells SketchUp to open a new window in the user's default web browser
 * outside of SketchUp.
 * @param {string} url Full url you'd like to open.
 */
skp.openURL = function(url) {
  su.callRuby('do_open_url', {'url': url});
};

/**
 * Tells SketchUp to resize and reposition the current dialog that this
 * javascript call is made from. (Note that the x and y parameters may be
 * overridden by a user's local settings, so repositioning may not work
 * in all cases.)
 * @param {number} w Width of the new dialog, in pixels.
 * @param {number} h Height of the new dialog, in pixels.
 * @param {number} opt_x The X or left of the new dialog, in pixels.
 * @param {number} opt_y The Y or top of the new dialog, in pixels.
 */
skp.dialog.setSize = function(w, h, opt_x, opt_y) {
  su.callRuby('set_dialog_properties', {
    'w': w,
    'h': h,
    'x': opt_x,
    'y': opt_y
  });
};

/**
 * Tells SketchUp to close the current dialog.
*/
skp.dialog.close = function() {
  su.callRuby('do_close');
};

/**
 * Sends an "action" down to SketchUp. These actions can be any string from
 * the list of ruby api actions, available at:
 *    http://download.su.com/OnlineDoc/gsu6_ruby/Docs/ruby-su.html
 * Also, there are four additional actions made available specifically to this
 * js API:
 * "generateModelXML:" Tells the Dynamic Components plugin to create a
 *     local text file report of the dynamic attributes across an entire
 *     model.
 * "generateSelectionXML:" Tells the Dynamic Components plugin to create a
 *     local text file report of the dynamic attributes across the current
 *     selection.
 * "generateSelectionCSV:" and "generateModelCSV:" do the same, but
 *     specify a CSV format instead of xml.
 * @param {string} action The action to send.
 */
skp.sendAction = function(action) {
  su.callRuby('do_send_action', {'action': action });
};

/**
 * Requests a JSON report of the dynamic attributes attached to the current
 * model. This will return a JSON structure that has parsed all of the Dynamic
 * Component "meta attributes" into friendly named variables. Here is an
 * example object that might be returned with a single component in the model.
 * Note that the formula is present as a subvariable on lenx, whereas the
 * actual Sketchup-side implementation is for the formula to be stored in a
 * "meta attribute" called _lenx_formula.
 *
 * { entities[
 *   { name: "myPart",
 *     typename: "ComponentInstance",
 *     id: 1234,
 *     file: 'myPart.skp',
 *     guid: '{g1234}',
 *     description: 'My Part',
 *     attributeDictionaries: {
 *       dynamic_attributes: {
 *         lenx: { value: "10" },
 *         leny: { value: "20", label: "Length Y", formula: "lenx*2" }
 *       }
 *     }
 *   }
 * ]}
 *
 * @param {function} onDataCallback Pointer to a function that will be
 *     called once the data has been received.
 * @param {boolean} opt_isDeep Whether to get all nested attributes.
 *     Optional. Defaults to true.
 */
skp.activeModel.getDynamicAttributes = function(onDataCallback, opt_isDeep) {
  var deep = su.ifEmpty(opt_isDeep, true);
  su.wrapperOnSuccess_ = onDataCallback;
  su.callRuby('pull_attribute_tree',
    {'selection_ids': 'active_model',
     'onsuccess': 'su.handleWrapperSuccess',
     'deep': deep });
};

/**
 * Requests a JSON report of the raw SU attributes attached to the current
 * model and its entities. Unlike activeModel.getDynamicAttributes, this
 * method will return the raw Sketchup "meta attribute" data, such as:
 *
 * { entities[
 *   { name: "myPart",
 *     typename: "ComponentInstance",
 *     id: 1234,
 *     file: 'myPart.skp',
 *     guid: '{g1234}',
 *     description: 'My Part',
 *     attributeDictionaries: {
 *       dynamic_attributes: {
 *         lenx: "10",
 *         leny: "20",
 *         _leny_label: "Length Y",
 *         _leny_formula: "lenx*2"
 *       }
 *     }
 *   }
 * ]}
 *
 * @param {function} onDataCallback Pointer to a function that will be
 *     called once the data has been received.
 * @param {boolean} opt_isDeep Whether to get all nested attributes.
 *     Optional. Defaults to true.
 * @param {string} opt_dictionary Specific name of a dictionary to pull.
 *     Optional.
 */
skp.activeModel.getAttributes = function(onDataCallback, opt_isDeep,
    opt_dictionary) {
  var deep = su.ifEmpty(opt_isDeep, true);
  su.wrapperOnSuccess_ = onDataCallback;
  var dictionary = su.ifEmpty(opt_dictionary, 'all_dictionaries')
  su.callRuby('pull_attribute_tree',
    {'selection_ids': 'active_model',
     'onsuccess': 'su.handleWrapperSuccess',
     'deep': deep,
     'dictionary': dictionary });
};

/**
 * Requests a JSON report of the dynamic attributes attached to the current
 * selection.
 * @param {function} onDataCallback Pointer to a function that will be
 *     called once the data has been received.
 * @param {boolean} opt_isDeep Whether to get all nested attributes.
 *     Optional. Defaults to true.
 */
skp.activeModel.selection.getDynamicAttributes = function(onDataCallback,
    opt_isDeep) {
  var deep = su.ifEmpty(opt_isDeep, true);
  su.wrapperOnSuccess_ = onDataCallback;
  su.callRuby('pull_attribute_tree', {
    'selection_ids': 'selection',
    'onsuccess': 'su.handleWrapperSuccess',
    'deep': deep
  });
};

/**
 * Asks SketchUp to place a component that is already loaded into the SketchUp
 * model.
 * @param {string} definitionID SketchUp ID of the definition we want to place.
 * @param {Object} opt_attributes Name/Value pairs of any DC attributes that
 *     we to attach to our new instance. If this object is present, then we
 *     will also do a redraw of the DC after it's placed.
 */
skp.activeModel.placeComponent = function(definitionID, opt_attributes) {
  if (su.isEmpty(opt_attributes)) {
    opt_attributes = {};
  }
  opt_attributes.definition_id = definitionID;
  su.callRuby('do_place_component', opt_attributes);
};

/**
 * Asks SketchUp to load a component from a URL into the definitions. It will
 * call the onDataCallback callback with an object containing an entityID
 * variable if successful, or an error if unsuccessful.
 * @param {string} url URL to download a SKP file from.
 * @param {function} onDataCallback Function to call when complete.
 */
skp.activeModel.definitions.loadFromURL = function(url, onDataCallback) {
  su.wrapperOnSuccess_ = onDataCallback;
  su.callRuby('do_load_from_url',
    {'url': url,
     'onsuccess': 'su.handleWrapperSuccess'});
};


//  --------------------------------------------------------------------------
//  Logging/Debugging
//  --------------------------------------------------------------------------

/**
 * Logs a message to the SketchUp Ruby console on behalf of JavaScript. The
 * message can be provided either as a string, or in an object containing a
 * key of 'message' and the message content as the value for that key.
 * @param {string|Object} message The message to log in string form, or
 *     an object defining keys including a 'separator', 'prefix', 'timestamp',
 *     and 'message' to be output to the log.
 */
su.log = function(message) {
  var obj;

  if (su.isString(message)) {
    obj = {
      'timestamp': (new Date()).getTime(),
      'prefix': 'JS',
      'message': message
    };
  } else {
    obj = message;
  }

  // Protect against errors in logging creating a recursive death spiral.
  try {
    su.callRuby('js_log', obj);
  } catch (e) {
    alert(message);
  }
};

/**
 * Outputs a message to a window, opening the window as needed. This is a
 * replacement for a simple alert call that offers scrolling for large output
 * strings common in debugging. Note that the message is not translated.
 * @param {string} message The message to output.
 * @param {string} windowName The name of the window to access or open.
 */
su.notify = function(message, windowName) {
  var arr = [];
  arr.push('<html><head>',
      '<link type="text/css" rel="stylesheet"',
        ' href="../css/su.css"/>',
      '</head><body>',
      '<div class="su-notify">',
        su.escapeHTML(message),
      '</div></body></html>');

  var name = su.ifEmpty(windowName, 'win' + (new Date()).getTime());
  var win = window.open('', name);
  if (!win) {
    return;
  }

  var html = arr.join('');
  win.document.open();
  win.document.write(html);
  win.document.close();
};

/**
 * Raises (throws) an error while offering the potential for logging and
 * call stack tracing.
 * @param {string|Error} message The error message to output or an Error
 *     object containing the message.
 * @param {Error} opt_err A native error object captured via a catch block.
 */
su.raise = function(message, opt_err) {
  if (su.isString(message)) {

    // If we have a message our first goal is to log it if possible. Once
    // that's been accomplished we can try to produce a valid Error and throw
    // that to trigger onerror hooks.
    try {
      su.log(message);
    } catch (e) {
      alert(message);
    }

    if (su.isValid(opt_err)) {
      throw opt_err;
    } else {
      throw new Error(message);
    }
  } else {
    // Presumably message is an Error so try to throw it.
    throw message;
  }
};

/**
 * Replace the standard onerror handler with one that should log to the Ruby
 * console or alert (based on configuration parameters).
 * @param {string} msg The error message reported by the browser.
 * @param {string} url The URL of the source file containing the error.
 * @param {string} line The line number where the error occurs.
 * @return {boolean} True to cause native error reports to be suppressed.
 */
window.onerror = function(msg, url, line) {
  // Uncomment this section for debugging, but keep commented out for
  // production use.
  //var msg = 'ERROR: ' + msg + ' @ ' +
  //    url.slice(url.lastIndexOf('/')) + '[' + line + ']';
  //alert(msg);

  // Suppress low-level errors here. These are typically things like
  // unterminated strings coming in from command input or results which
  // cause IE to display a visible error to the user.
  return true;
};

//  --------------------------------------------------------------------------
//  Object Representations
//  --------------------------------------------------------------------------

/**
 * Returns a string representation roughly equivalent to JSON/JavaScript
 * source code format which is useful for debugging object structures.
 * @param {Object} anObject The object to produce a debug string for.
 * @param {Array} opt_buffer An internal parameter passed by the routine
 *     itself while recursively processing anObject.
 * @return {string} The object in debug string format.
 */
su.inspect = function(anObject, opt_buffer) {
  var str;
  var len;
  var keys;
  var i;

  var arr = su.ifUndefined(opt_buffer, []);

  if (anObject === null) {
    arr.push('null');
  } else if (anObject === undefined) {
    arr.push('undefined');
  } else if (su.isString(anObject)) {
    str = su.quote(anObject);
    arr.push(str);
  } else if (su.isDate(anObject)) {
    // Dates won't work properly if left unquoted. they won't come back as
    // valid Date instances unless we use Date(anObject.getTime()) as our
    // string either, but at least they won't cause syntax errors for eval.
    str = su.quote(anObject);
    arr.push(str);
  } else if (su.isScalar(anObject)) {
    if (su.canCall(anObject, 'toString')) {
      arr.push(anObject.toString());
    } else {
      arr.push('' + anObject);
    }
  } else if (su.isJSArray(anObject)) {
    arr.push('[');
    len = anObject.length;
    for (i = 0; i < len; i++) {
      arr.push(su.inspect(anObject[i]));
      if (i + 1 < len) {
        arr.push(', ');
      }
    }
    arr.push(']');
  } else {
    arr.push('{');
    keys = su.getKeys(anObject);
    len = keys.length;
    for (i = 0; i < len; i++) {
      arr.push(keys[i], ':');
      arr.push(su.inspect(anObject[keys[i]]));
      if (i + 1 < len) {
        arr.push(', ');
      }
    }
    arr.push('}');
  }

  return arr.join('');
};

/**
 * Resolves an object path, a dot-separated name such as su.resolveObjectPath
 * by splitting on '.' and traversing to locate the leaf object.
 * @param {string} aPath The object path to attempt to resolve.
 * @return {Object?} The object found via the path.
 */
su.resolveObjectPath = function(aPath) {
  if (su.isEmpty(aPath)) {
    return;
  }

  var obj = self;
  var parts = aPath.split('.');
  var len = parts.length;
  for (var i = 0; i < len; i++) {
    try {
      obj = obj[parts[i]];
      if (su.notValid(obj)) {
        break;
      }
    } catch (e) {
      obj = null;
    }
  }

  return obj;
};

//  --------------------------------------------------------------------------
//  Object Testing
//  --------------------------------------------------------------------------

/**
 * Adds a value to hash if the key currently doesn't map to a valid value.
 * This is a useful way to augment a request object with default values.
 * @param {Object} hash The object to add missing key/value pairs to.
 * @param {string} key The key to check for existence.
 * @param {Object} value The value to set if the key is missing/empty.
 * @return {Object?} The value of the key after the set operation.
 */
su.addIfAbsent = function(hash, key, value) {
  if (su.notValid(hash)) {
    return;
  }

  if (su.notValid(hash[key])) {
    hash[key] = value;
  }

  return hash[key];
};

/**
 * Returns true if the object provided supports the named function. This is
 * a reasonable way of testing whether a method can be invoked on an object.
 * @param {Object} suspect The object to test.
 * @param {string} funcname The name of the function to test for.
 * @return {boolean} True if the object supports the named function.
 */
su.canCall = function(suspect, funcname) {
  if (su.notValid(suspect)) {
    return false;
  }

  return su.isFunction(suspect[funcname]);
};

/**
 * Returns the fallback value if the key is not found in the target object
 * provided. Note that this can occur either because the object isn't valid
 * or the key isn't found or isEmpty.
 * @param {Object} hash The object to test.
 * @param {string} key The key to look up.
 * @param {Object} fallback The value to return if the key is not found.
 * @return {Object} The suspect or fallback value based on isEmpty status.
 */
su.ifAbsent = function(hash, key, fallback) {
  if (su.isEmpty(hash)) {
    return fallback;
  }

  return su.ifEmpty(hash[key], fallback);
};

/**
 * Returns the fallback value if the first parameter isEmpty.
 * @param {Object} suspect The object to test.
 * @param {Object} fallback The value to return if the suspect isEmpty.
 * @return {Object} The suspect or fallback value based on isEmpty status.
 */
su.ifEmpty = function(suspect, fallback) {
  return su.isEmpty(suspect) ? fallback : suspect;
};

/**
 * Returns the fallback value if the first parameter is notValid.
 * @param {object} suspect  The object to test.
 * @param {object} fallback The value to return if the suspect is notValid.
 * @return {object} The suspect or fallback value based on notValid state.
 */
su.ifInvalid = function(suspect, fallback) {
  return su.notValid(suspect) ? fallback : suspect;
};

/**
 * Returns the fallback value if the first parameter == undefined.
 * @param {Object} suspect The object to test.
 * @param {Object} fallback The value to return if the suspect isEmpty.
 * @return {Object} The suspect or fallback value based on isEmpty status.
 */
su.ifUndefined = function(suspect, fallback) {
  return su.isDefined(suspect) ? suspect : fallback;
};

/**
 * Returns true if the object provided is a Date instance.
 * @param {Object} suspect The object to test.
 * @return {boolean} True if the object is a Date instance.
 */
su.isDate = function(suspect) {
  // Note that this relies on the object being in the same frame/window.
  return (suspect != null) && (suspect.constructor === Date);
};

/**
 * Returns true if the suspect object is defined (meaning not explicitly
 * undefined).
 * @param {Object} suspect The object to test.
 * @return {boolean} True if the suspect value is defined.
 */
su.isDefined = function(suspect) {
  return typeof suspect != 'undefined';
};

/**
 * Returns true if the object provided is null, undefined, or the empty
 * string.
 * @param {Object} suspect The object to test.
 * @return {boolean} True if the object is null, undefined, or ''.
 */
su.isEmpty = function(suspect) {
  return (suspect == null) || (suspect === '') || (suspect.length == 0);
};

/**
 * Returns true if the object provided is an instance of Function.
 * @param {Object} suspect The object to test.
 * @return {boolean} True if the object is a function.
 */
su.isFunction = function(suspect) {
  // IE has a lot of exceptions to this rule, but this is adequate.
  return typeof suspect == 'function' &&
      suspect.toString().indexOf('function') == 0;
};

/**
 * Returns true if the suspect object is a valid Array instance. Note that
 * this would be called isArray but that's been taken by historical calls
 * testing to see if an object is a Java array.
 * @param {object} suspect The object to test.
 * @return {boolean} True if the suspect value is a JavaScript array.
 */
su.isJSArray = function(suspect) {
  // Note that this relies on the object being in the same frame/window.
  return (suspect != null) && (suspect.constructor === Array);
};

/**
 * Returns true if the string provided appears to contain markup. This is
 * used during content management to determine how to best update and
 * element's content. Note that for this function to return true the string
 * must start and end with < and > after whitespace is trimmed from each
 * end of the string.
 * @param {string} suspect The string to test.
 * @return {boolean} True if the string appears to contain markup.
 */
su.isMarkup = function(suspect) {
  if (!su.isString(suspect)) {
    return false;
  }

  var str = suspect.replace(/^\s*(.+?)\s*$/, '$1');

  return /^<(.*)>$/.test(str);
};

/**
 * Returns true if the object provided is precisely a null. Note that this
 * method will return false when the input object is undefined.
 * @param {Object} suspect The object to test.
 * @return {boolean} True if the object is precisely null.
 */
su.isNull = function(suspect) {
  return suspect === null;
};

/**
 * Returns true if the object provided is a number instance. Note that
 * unlike a simple typeof check this function returns false for values which
 * are isNaN allowing su.isNumber(parse[Int|Float](someval)) to work.
 * @param {Object} suspect The object to test.
 * @return {boolean} True if the object is a number instance.
 */
su.isNumber = function(suspect) {
  if (isNaN(suspect)) {
    return false;
  }

  return typeof suspect == 'number';
};

/**
 * Returns true if the object provided is a scalar object, one whose value
 * is roughly atomic (as opposed to an Array or Object/Hash instance).
 * @param {Object} suspect The object to test.
 * @return {boolean} True if the object is a scalar type instance.
 */
su.isScalar = function(suspect) {
  if (su.isJSArray(suspect)) {
    return false;
  }

  // Note that this relies on the object being in the same frame/window.
  return (suspect != null) && (suspect.constructor !== Object);
};

/**
 * Returns true if the object provided is a string instance.
 * @param {Object} suspect The object to test.
 * @return {boolean} True if the object is a string instance.
 */
su.isString = function(suspect) {
  return typeof suspect == 'string';
};

/**
 * Returns true if the object provided is null or undefined. This is the
 * preferred method for testing values for existence rather than relying on
 * if (obj) where an implicit boolean type conversion may create a bug.
 * @param {Object} suspect The object to test.
 * @return {boolean} True if the object is null or undefined.
 */
su.isValid = function(suspect) {
  return suspect != null;
};

/**
 * Returns true if the suspect element is visible, meaning that it's display
 * and visibility properties imply it should be rendered in the page flow.
 * @param {string|Element} elementOrID The element or element ID to find.
 * @return {boolean} True if the element is found and appears visible.
 */
su.isVisible = function(elementOrID) {
  var el = $(elementOrID);
  if (su.notValid(el)) {
    return false;
  }

  if (el.style.display == 'none') {
    return false;
  }

  return el.style.visibility != 'hidden';
};

/**
 * Returns true if the object provided isValid and is not ''. This is
 * the preferred method for testing to ensure a viable string value exists.
 * @param {Object} suspect The object to test.
 * @return {boolean} True if the object is valid and not the empty string.
 */
su.notEmpty = function(suspect) {
  return !su.isEmpty(suspect);
};

/**
 * Returns true if the object provided is neither null or undefined. This is
 * the preferred method for testing values for non-existence rather than
 * relying on if (obj) where an implicit boolean type conversion may create
 * a bug.
 * @param {Object} suspect The object to test.
 * @return {boolean} True if the object is neither null nor undefined.
 */
su.notValid = function(suspect) {
  return suspect == null;
};

//  --------------------------------------------------------------------------
//  Attribute Management
//  --------------------------------------------------------------------------

/**
 * Returns the SketchUp attribute object (containing value, units, etc)
 * found in the attribute dictionary and attribute name provided.
 * @param {Object} entity The object to search for dictionary data.
 * @param {string} dictionary The name of the attribute dictionary.
 * @param {string} attribute The name of the attribute to locate.
 * @return {Object?} The attribute value.
 */
su.getAttribute = function(entity, dictionary, attribute) {
  var dict = su.getDictionary(entity, dictionary);
  if (su.notValid(dict)) {
    return;
  }

  return dict[attribute];
};

/**
 * Returns the SketchUp attribute dictionary with the name provided.
 * @param {Object} entity The object to search for dictionary data.
 * @param {string} dictionary The name of the attribute dictionary.
 * @return {Object?} The named dictionary.
 */
su.getDictionary = function(entity, dictionary) {
  if (su.notValid(entity)) {
    su.raise(su.translateString(
        'Invalid entity. Unable to retrieve attribute dictionary.'));
    return;
  }

  var dicts = entity.attributeDictionaries;
  if (su.notValid(dicts)) {
    return;
  }

  return dicts[dictionary];
};

/**
 * Returns true if the named attribute exists in the identified entity.
 * object attribute dictionary.
 * @param {Object} entity The object to search.
 * @param {string} dictionary The name of the attribute dictionary.
 * @param {string} attribute The specific attribute name to locate.
 * @return {boolean} True if the named attribute exists.
 */
su.hasAttribute = function(entity, dictionary, attribute) {
  var dict = su.getDictionary(entity, dictionary);
  if (su.notValid(dict)) {
    return false;
  }

  return su.isDefined(dict[attribute]);
};

/**
 * Removes an attribute or attribute property. When a key is provided only
 * that key is removed from the attribute. When no key is provided the
 * entire attribute is removed from the dictionary.
 * @param {Object} entity The object to search for the attribute dictionary.
 * @param {string} dictionary The name of the attribute dictionary.
 * @param {string} attribute The name of the attribute to update.
 * @param {string} key The name of the aspect to update.
 * @return {boolean} True if the operation succeeded, false otherwise.
 */
su.removeAttribute = function(entity, dictionary, attribute, key) {
  var attr = su.getAttribute(entity, dictionary, attribute);

  if (su.notEmpty(key)) {
    if (su.isValid(attr)) {
      delete attr[key];
      return true;
    }
  } else {
    if (su.notValid(attr)) {
      return false;
    }

    var dicts = entity.attributeDictionaries;
    if (su.isValid(dicts)) {
      var dict = dicts[dictionary];
      if (su.isValid(dict)) {
        delete dict[attribute];
        return true;
      }
    }
  }

  return false;
};

/**
 * Sets an aspect of an named attribute to the value provided. The aspect
 * (aka key) is typically something such as 'value', 'units', or a similar
 * named property of a SketchUp attribute.
 * @param {Object} entity The object to search for the attribute dictionary.
 * @param {string} dictionary The name of the attribute dictionary.
 * @param {string} attribute The name of the attribute to update.
 * @param {string} key The name of the aspect to update.
 * @param {Object} value The value to set for the key.
 * @return {Object} The value after the set has been processed.
 */
su.setAttribute = function(entity, dictionary, attribute, key, value) {
  if (su.notValid(entity)) {
    su.raise(su.translateString('Invalid entity. No attributes can be set.'));
    return;
  }

  var attr = su.getAttribute(entity, dictionary, attribute);

  // Create attribute (and any portions of the path to that attribute) as
  // needed when the attribute can't be found.
  if (su.notValid(attr)) {
    var dicts = entity.attributeDictionaries;
    if (su.notValid(dicts)) {
      dicts = {};
      entity.attributeDictionaries = dicts;
    }

    var dict = dicts[dictionary];
    if (su.notValid(dict)) {
      dict = {};
      dicts[dictionary] = dict;
    }

    attr = {};
    dict[attribute] = attr;
  }

  attr[key] = value;

  return attr[key];
};

//  --------------------------------------------------------------------------
//  Collections
//  --------------------------------------------------------------------------

/**
 * Tests aCollection to see if it contains aValue and returns true when the
 * value is found.
 * @param {Object} aCollection The collection, typically an Array, to test.
 * @param {Object} aValue The value, typically a string, to search for.
 * @return {boolean} True when the value is found, false otherwise.
 */
su.contains = function(aCollection, aValue) {

  if (su.isJSArray(aCollection)) {
    var len = aCollection.length;
    for (var i = 0; i < len; i++) {
      if (aCollection[i] == aValue) {
        return true;
      }
    }
  }

  return false;
};

//  --------------------------------------------------------------------------
//  Content Management
//  --------------------------------------------------------------------------

/**
 * Returns the content of the element provided or identified by ID.
 * @param {string|Element} elementOrID The element or element ID to find.
 * @return {string} The HTML content of the element.
 */
su.getContent = function(elementOrID) {
  var el = $(elementOrID);
  if (su.isValid(el)) {
    return el.innerHTML;
  }
};

/**
 * Sets the content of the element provided or identified by ID. The content
 * is checked for HTML and stripped of any script tags which are found.
 * @param {string|Element} elementOrID The element or element ID to find.
 * @param {string} content The new content to use for the element.
 * @param {boolean} sanitize True to force the content to be safety-checked.
 * @return {Element} The element identified by elementOrID.
 */
su.setContent = function(elementOrID, content, sanitize) {
  var el = $(elementOrID);
  if (su.notValid(el)) {
    return;
  }

  var text = content || '';

  try {
    el.innerHTML = '' + text;
  } catch (e) {
    su.raise(su.translateString('Could not set content: ') + e.message);
  }

  return el;
};

//  --------------------------------------------------------------------------
//  DOM Operations
//  --------------------------------------------------------------------------

/**
 * Returns true if the element is a descendant of ancestor.
 * @param {Element} element The descendant element.
 * @param {Element} ancestor The ancestor to check for containment.
 * @return {boolean} True when ancestor contains element as a descendant.
 */
su.elementHasParent = function(element, ancestor) {

  var parent = element.parentNode;
  while (parent && (parent.nodeType == Node.ELEMENT_NODE)) {
    if (parent === ancestor) {
      return true;
    }
    parent = parent.parentNode;
  }

  return false;
};

//  --------------------------------------------------------------------------
//  Dynamic CSS
//  --------------------------------------------------------------------------

/**
 * Adds a new link element to the document provided, ensuring the new
 * element's HREF points to the css file URL provided.
 * @param {Document} doc The document receiving the new CSS link element.
 * @param {string} url The CSS style URL to add.
 * @return {Element} The newly created link element.
 */
su.addStylesheet = function(doc, url) {

  if (su.isEmpty(url)) {
    return;
  }

  if (/\.css$/.test(url) != true) {
    su.raise('Invalid CSS URL: ' + url);
    return;
  }

  var link = doc.createElement('link');

  link.setAttribute('type', 'text/css');
  link.setAttribute('rel', 'stylesheet');
  link.setAttribute('media', 'screen, projection');
  link.setAttribute('href', url);

  doc.getElementsByTagName('head')[0].appendChild(link);

  return link;
};

/**
 * Returns the current value for a specific style property of an element.
 * @param {string|Element} elementOrID The element or element ID to find.
 * @param {string} propertyName The style property to look up.
 * @return {string} The style property value.
 */
su.getComputedStyle = function(elementOrID, propertyName) {

  var styleObj;
  var el = $(elementOrID);

  if (su.IS_MAC) {
    styleObj = su.elementWindow(el).getComputedStyle(el, null);
  } else {
    styleObj = el.currentStyle;
  }

  if (su.isEmpty(propertyName)) {
    return styleObj;
  }

  return styleObj[propertyName];
};

/**
 * Removes a link element to the document provided, ensuring the sheet no
 * longer applies to the content.
 * @param {Document} doc The document whose link element is being removed.
 * @param {string} url The CSS style URL to remove.
 * @return {boolean} True if the link was found and removed.
 */
su.removeStylesheet = function(doc, url) {
  var list = doc.getElementsByTagName('link');
  var len = list.length;
  for (var i = 0; i < len; i++) {
    var link = list[i];
    if (link.getAttribute('href') == url) {
      link.setAttribute('disabled', true);
      link.parentNode.removeChild(link);
      return true;
    }
  }

  return false;
};

//  --------------------------------------------------------------------------
//  Dynamic HTML
//  --------------------------------------------------------------------------

/**
 * Sets the disabled state of an element to true, rendering it incapable of
 * action. This is the inverse of the su.enable function.
 * @param {string|Element} elementOrID The element or element ID to find.
 * @return {Element} The element that was disabled.
 */
su.disable = function(elementOrID) {
  var el = $(elementOrID);
  if (su.isValid(el)) {
    el.disabled = true;
  }

  return el;
};

/**
 * Returns the true border box for an element, allowing accurate computation
 * of a global X, Y coordinate as well as width/height.
 * @param {string|Element} elementOrID The element or element ID to find.
 * @return {Object} An object whose keys are 'top','right','bottom', and
 *     'left', and which contains the border box dimensions and location.
 */
su.elementGetBorderBox = function(elementOrID) {
  var element = $(elementOrID);
  var elementWin = su.elementWindow(element);
  var elementDoc = elementWin.document;

  if (su.IS_MAC) {

    var offsetX = element.offsetLeft;
    var offsetY = element.offsetTop;

    var lastOffset = element;
    var styleObj = elementWin.getComputedStyle(element, null);
    var addDocScroll = (styleObj.position == 'fixed');

    var offsetParent = element.offsetParent;

    // Compute in all of the offset parents.
    while (su.isValid(offsetParent)) {

      // Add the offsets themselves.
      offsetX += offsetParent.offsetLeft;
      offsetY += offsetParent.offsetTop;

      // Safari does not include the border on offset parents,
      offsetX += su.elementGetBorderInPixels_(offsetParent, 'LEFT');
      offsetY += su.elementGetBorderInPixels_(offsetParent, 'TOP');

      styleObj = elementWin.getComputedStyle(offsetParent, null);

      // If any of the offset parents have a position of 'fixed',
      // then we'll want to add in the document scroll values later.
      if (addDocScroll == false && styleObj.position == 'fixed') {
        addDocScroll = true;
      }

      // Keep track of the last offsetParent (unless it's the body).
      if (/^body$/i.test(offsetParent.tagName) == false) {
        lastOffset = offsetParent;
      }

      offsetParent = offsetParent.offsetParent;
    }

    var elemParent = element.parentNode;

    // Compute in all of the scroll values of the parentNodes (not
    // necessarily the offset parents).
    while (elemParent && elemParent.tagName &&
        /^(body|html)$/i.test(elemParent.tagName) == false) {

      var parentStyle = elementWin.getComputedStyle(elemParent, null);

      //  Subtract the scroll amounts unless the parent is 'inline'
      //  or 'table'.
      if (/^inline|table.*$/.test(parentStyle.display) == false) {
        offsetX -= elemParent.scrollLeft;
        offsetY -= elemParent.scrollTop;
      }

      elemParent = elemParent.parentNode;
    }

    //  If we're supposed to add in the document scroll values because
    //  this flag got flipped above, then do so now.
    if (addDocScroll == true) {
      offsetX += elementWin.pageXOffset;
      offsetY += elementWin.pageYOffset;
    }

    offsetWidth = element.offsetWidth;
    offsetHeight = element.offsetHeight;

  } else {

    var elementBox = element.getBoundingClientRect();

    var offsetX = elementBox.left;
    var offsetY = elementBox.top;

    var offsetWidth = elementBox.right - offsetX;
    var offsetHeight = elementBox.bottom - offsetY;

    // Don't overlook adjusting for scrolling, but note that we have to
    // determine this based on the compatibility mode of the document.
    var scrollX = (elementDoc.compatMode == 'CSS1Compat') ?
        document.documentElement.scrollLeft :
        document.body.scrollLeft;
    offsetX += scrollX;

    var scrollY = (elementDoc.compatMode == 'CSS1Compat') ?
        document.documentElement.scrollTop :
        document.body.scrollTop;
    offsetY += scrollY;

    // Note also that getClientBoundingRect returns "border box" dimensions
    // so we compensate for the document element offsets from the true box.
    offsetX -= elementDoc.documentElement.clientLeft;
    offsetY -= elementDoc.documentElement.clientTop;
  }

  var box = {
    'left': offsetX,
    'top': offsetY,
    'width': offsetWidth,
    'height': offsetHeight
  };

  return box;
};

/**
 * Returns the border size, in pixels, for a particular side of an element.
 * Side should be specified as 'TOP', 'RIGHT', 'BOTTOM', or 'LEFT'.
 * @param {string|Element} elementOrID The element or element ID to find.
 * @param {string} side The side, as an uppercase value.
 * @return {number} The width of the border in pixels.
 * @private
 */
su.elementGetBorderInPixels_ = function(elementOrID, side)
{
  var computedStyle;
  var valueInPixels = 0;
  var element = $(elementOrID);

  if (su.IS_MAC == true) {

    // Grab the computed style for the element.
    computedStyle = su.elementWindow(element).getComputedStyle(element,
        null);

    try {
      switch (side) {
        case 'TOP':
          valueInPixels = computedStyle.getPropertyCSSValue(
              'border-top-width').getFloatValue(
              CSSPrimitiveValue.CSS_PX);
          break;

        case 'RIGHT':
          valueInPixels = computedStyle.getPropertyCSSValue(
              'border-right-width').getFloatValue(
              CSSPrimitiveValue.CSS_PX);
          break;

        case 'BOTTOM':
          valueInPixels = computedStyle.getPropertyCSSValue(
              'border-bottom-width').getFloatValue(
              CSSPrimitiveValue.CSS_PX);
          break;

        case 'LEFT':
          valueInPixels = computedStyle.getPropertyCSSValue(
              'border-left-width').getFloatValue(
              CSSPrimitiveValue.CSS_PX);
          break;
      }
    } catch (e) {
      // Our valueInPixels is already set to 0. Nothing to do here.
    }
  } else {

    computedStyle = element.currentStyle;

    switch (side) {
      case 'TOP':
        valueInPixels = computedStyle.borderTopWidth;
        break;
      case 'RIGHT':
        valueInPixels = computedStyle.borderRightWidth;
        break;
      case 'BOTTOM':
        valueInPixels = computedStyle.borderBottomWidth;
        break;
      case 'LEFT':
        valueInPixels = computedStyle.borderLeftWidth;
        break;
    }

    valueInPixels = Math.max(parseFloat(valueInPixels), 0);
  }

  return valueInPixels;
};

/**
 * Returns the height in pixels of the element provided.
 * @param {string|Element} elementOrID The element or element ID to find.
 * @return {number} A height in pixels.
 */
su.elementHeight = function(elementOrID) {
  var box = su.elementGetBorderBox(elementOrID);
  return box.height;
};

/**
 * Returns the width in pixels of the element provided.
 * @param {string|Element} elementOrID The element or element ID to find.
 * @return {number} A width in pixels.
 */
su.elementWidth = function(elementOrID) {
  var box = su.elementGetBorderBox(elementOrID);
  return box.width;
};

/**
 * Returns the window for the element provided.
 * @param {string|Element} elementOrID The element or element ID to find.
 * @return {Window} Returns the element's containing window.
 */
su.elementWindow = function(elementOrID) {
  var el = $(elementOrID);
  if (su.IS_MAC) {
    return el.ownerDocument.defaultView;
  } else {
    return el.ownerDocument.parentWindow;
  }
};

/**
 * Returns the X coordinate, in pixels, of the top left corner of the
 * element.
 * @param {string|Element} elementOrID The element or element ID to find.
 * @return {number} An X coordinate in pixels.
 */
su.elementX = function(elementOrID) {
  var box = su.elementGetBorderBox(elementOrID);
  return box.left;
};

/**
 * Returns the Y coordinate, in pixels, of the top left corner of the
 * element.
 * @param {string|Element} elementOrID The element or element ID to find.
 * @return {number} A Y coordinate in pixels.
 */
su.elementY = function(elementOrID) {
  var box = su.elementGetBorderBox(elementOrID);
  return box.top;
};

/**
 * Sets the disabled state of an element to false, returning it to an
 * enabled state. This is the inverse of the su.disable function.
 * @param {string|Element} elementOrID The element or element ID to find.
 * @return {Element} The element that was enabled.
 */
su.enable = function(elementOrID) {
  var el = $(elementOrID);
  if (su.isValid(el)) {
    el.disabled = false;
  }

  return el;
};

/**
 * Sets the visiblity of an element to 'hidden'. This is the inverse of the
 * su.show function.
 * @param {string|Element} elementOrID The element or element ID to find.
 * @return {Element} The element that was hidden.
 */
su.hide = function(elementOrID) {
  var el = $(elementOrID);
  if (su.isValid(el)) {
    var display = su.getComputedStyle(el, 'display');
    if (display != 'none') {
      el.original_display = display;
    }
    el.style.display = 'none';
    el.style.visibility = 'hidden';
  }

  return el;
};

/**
 * Sets the visibility of an element to 'visible'. This is the inverse of
 * the su.hide function.
 * @param {string|Element} elementOrID The element or element ID to find.
 * @return {Element} The element that was shown.
 */
su.show = function(elementOrID) {
  var el = $(elementOrID);
  if (su.isValid(el)) {
    var display = su.ifEmpty(el.original_display, 'block');
    el.style.display = display;
    el.style.visibility = 'visible';
  }

  return el;
};

//  --------------------------------------------------------------------------
//  Entity Management
//  --------------------------------------------------------------------------

// Entities are effectively visual elements in the SketchUp model. An entity
// seen from JavaScript is just a data structure consisting of specific key
// and value pairs and specific child dictionary and array content. Entity
// data is built by the Ruby API in JSON format and sent to JavaScript via the
// JavaScript/Ruby bridge (see that section in this file for more info).
//
// Unlike the JavaScript DOM, entities don't have parent links, so searches
// for parents must descend from a root which should contain the child.
// Additional variations from JavaScript also exist, hence special functions
// are implemented to manage entities different from typical DOM actions.

/**
 * Returns a specific subentity dictionary from a parent entity.
 * @param {string} id The subentity ID to search for.
 * @param {Object} entity The parent entity to search.
 * @param {boolean} deep False to turn off deep searching.
 * @return {Object?} The entity with ID id.
 */
su.findEntity = function(id, entity, deep) {
  if (su.notValid(entity)) {
    su.raise(su.translateString(
        'Invalid parent entity. Cannot find subentity.'));
    return;
  }

  if (entity.id == id) {
    return entity;
  }

  // No children? No chance of finding it then.
  var subs = entity.subentities;
  if (su.notValid(subs)) {
    return;
  }

  // Check each subentity, optionally recursing if this is a deep search.
  var len = subs.length;
  for (var i = 0; i < len; i++) {
    var sub = subs[i];
    if (sub.id == id) {
      return sub;
    }
    if (deep != false) {
      var descendant = su.findEntity(id, sub, deep);
      if (su.isValid(descendant)) {
        return descendant;
      }
    }
  }
};

/**
 * Returns the direct parent entity for the entity ID provided, starting the
 * search within the entity given. If deep is not false then the search is
 * done across the entire tree of entities.
 * @param {string} id The subentity ID to search for.
 * @param {Object} entity The parent entity to search.
 * @param {boolean} deep False to turn off deep searching.
 * @return {Object?} The parent of the entity with ID id.
 */
su.findEntityParent = function(id, entity, deep) {
  if (su.notValid(entity)) {
    su.raise(su.translateString(
        'Invalid parent entity. Cannot find subentity parent.'));
    return;
  }

  if (entity.id == id) {
    return;
  }

  // No children? No chance of finding it then.
  var subs = entity.subentities;
  if (su.notValid(subs)) {
    return;
  }

  // Check each subentity, optionally recursing if this is a deep search.
  var len = subs.length;
  for (var i = 0; i < len; i++) {
    var sub = subs[i];
    if (sub.id == id) {
      // Note that when we find a first-level subentity the parent we
      // return is the entity that rooted this level's search.
      return entity;
    }
    if (deep != false) {
      var ancestor = su.findEntityParent(id, sub, deep);
      if (su.isValid(ancestor)) {
        return ancestor;
      }
    }
  }
};

//  --------------------------------------------------------------------------
//  Event Management
//  --------------------------------------------------------------------------

/**
 * Returns the key code from the event provided, or the current window event
 * when no event is specified.
 * @param {Event} opt_evt The native keyboard event.
 * @return {number} The key code.
 */
su.getKeyCode = function(opt_evt) {
  var ev = opt_evt || window.event;
  var code = su.ifInvalid(ev.keyCode, ev.which);

  return code;
};

/**
 * Returns the key code from the event provided, or the current window event
 * when no event is specified.
 * @param {Event} opt_evt The native keyboard event.
 * @return {number} The key code.
 */
su.getShiftKey = function(opt_evt) {
  var ev = opt_evt || window.event;
  return ev.shiftKey;
};

/**
 * Prevents default event handling for the event provided, or the current
 * window event when no event is specified.
 * @param {Event} opt_evt The native event.
 * @return {boolean} A true or false value appropriate to the event.
 */
su.preventDefault = function(opt_evt) {
  var ev = opt_evt || window.event;

  if (su.canCall(ev, 'preventDefault')) {
    ev.preventDefault();
  } else {
    if (ev.type == 'mouseout') {
      ev.returnValue = true;
      return true;
    } else {
      ev.returnValue = false;
    }
  }

  return false;
};

/**
 * Cancels event propagation (and bubbling) for the event provided, or the
 * current window event when none is provided. Note that this will only work
 * on Event instances which support cancellation.
 * @param {Event} opt_evt The native event.
 * @return {boolean} A true or false value appropriate to the event.
 */
su.stopPropagation = function(opt_evt) {
  var ev = opt_evt || window.event;

  if (su.canCall(ev, 'stopPropagation')) {
    ev.stopPropagation();
  } else {
    ev.cancelBubble = true;
  }

  return false;
};

//  --------------------------------------------------------------------------
//  Formatting/Translation
//  --------------------------------------------------------------------------

/**
 * Escapes HTML entities, making sure the returned string can be used in
 * HTML content effectively.
 * @param {string} text The string to escape.
 * @return {string} The escaped text.
 */
su.escapeHTML = function(text) {
  return text.replace(/&/g, '&amp;'
    ).replace(/"/g, '&quot;'
    ).replace(/'/g, '&#39;'
    ).replace(/</g, '&lt;'
    ).replace(/>/g, '&gt;'
    ).replace(/\\/g, '&#92;');
};

/**
 * Formats an object length, providing the formatted length to JavaScript
 * via the Ruby/JS bridge. To acquire the results the request must include a
 * key of oncomplete or onsuccess naming a valid callback function. The
 * length to format should be provided in the 'length' key of the request.
 * @param {Object} request An object providing a 'length' key containing
 *     the length to format and one or more optional callback specifiers per
 *     Ruby/JS bridge specs.
 */
su.formatLength = function(request) {
  su.callRuby('pull_format_length', request);
};

/**
 * Responds to notification that a call for Sketchup information has been
 * completed successfully.
 * @param {string} queryid The unique ID of the invocation used to call
 *     Ruby for Sketchup data.
 */
su.handlePullInformationSuccess = function(queryid) {
  su.info = su.getRubyResponse(queryid);
  su.strings = su.info.strings;
};

/**
 * Responds to notification that a call for Sketchup attribute report has
 * been received. Used by the following wrapper functions:
 *     su.activeModel.getDynamicAttributes
 *     su.activeModel.seletion.getDynamicAttributes
 * @param {string} queryid The unique ID of the invocation used to call Ruby
 *     Ruby for Sketchup data.
 */
su.handleWrapperSuccess = function(queryid) {
  var obj = su.getRubyResponse(queryid);
  su.wrapperOnSuccess_(obj);
};

/**
 * Responds to notification of successful translation of a set of strings.
 * This routine is responsible for loading the translation dictionary used
 * by the single-string method translateString.
 * @param {string} queryid The unique ID of the invocation used to call Ruby
 *     for translation data.
 */
su.handlePullTranslationsSuccess = function(queryid) {
  su.strings = su.getRubyResponse(queryid);
};

/**
 * Returns a single-quoted version of the input value with any embedded single
 * quotes escaped.
 * @param {Object} aValue The object whose string value should be quoted.
 * @return {string} The quoted string value.
 */
su.quote = function(aValue) {
  var str;

  if (aValue === null) {
    str = 'null';
  } else if (aValue === undefined) {
    str = 'undefined';
  } else if (su.canCall(aValue, 'toString')) {
    str = aValue.toString();
  } else {
    // Even though su.canCall(aValue, 'toString') should work in all cases,
    // it does not. Converting via concatenation fixes a bug that can throw
    // errors on IE.
    str = aValue + '';
  }

  return "'" + str.replace(/([^\\])'/g, "$1\\'") + "'";
};

/**
 * Translates a string by checking a local dictionary of string values.
 * Lookup data is populated from Ruby via the pull_translations API call.
 * @param {string} text The string to translate.
 * @return {string} The translated text.
 */
su.translateString = function(text) {
  var str;

  if (su.isValid(su.strings)) {
    str = su.strings[text];
    if (su.isEmpty(str)) {
      // Look for a match on a string with quotes encoded. This is to handle
      // the fact that we encode this character when it goes over the bridge.
      str = su.strings[text.replace(/\"/g, '&quot;')];
    }
  }

  return su.notEmpty(str) ? str : text;
};

/**
 * Removes leading and trailing whitespace of any kind from aString.
 * @param {string} aString The string to trim.
 * @return {string} A string with no leading/trailing whitespace.
 */
su.trimWhitespace = function(aString)
{
  var str = aString.replace(/^\s\s*/, '');
  var ws = /\s/;
  var i = str.length;
  while (ws.test(str.charAt(--i))) {
  }
  return str.slice(0, i + 1);
};

/**
 * Truncates a String to a certain length (if longer than that length) and
 * adds an ellipsis.
 * @param {string} aString The string to truncate.
 * @param {number} aLength The length to truncate the string to.
 * @return {string} The string truncated to the length given.
 */
su.truncate = function(aString, aLength)
{
  if (aString.length <= aLength) {
    return aString;
  }

  return aString.substr(0, aLength - 3) + '...';
};

/**
 * Unescapes HTML entities, converting '&lt;' into a less-than symbol etc.
 * @param {string} text The string to unescape.
 * @return {string} The unescaped text.
 */
su.unescapeHTML = function(text) {
  // Force convert to a string.
  text = text + '';
  return text.replace(/&amp;/g, '&'
    ).replace(/&quot;/g, '"'
    ).replace(/&#39;/g, "'"
    ).replace(/&apos;/g, "'"
    ).replace(/&lt;/g, '<'
    ).replace(/&gt;/g, '>'
    ).replace(/&nbsp;/g, ' '
    ).replace(/&#92;/g, '\\'
    ).replace(/^\s*(.*)\s$/, '$1');
};

/**
 * Returns a url-encoded string built from the text provided. The string's
 * content is escaped to ensure that after SketchUp processes the string the
 * proper escapes remain.
 * @param {string} text The text to encode.
 * @return {string} The url-encoded string.
 */
su.urlEncode = function(text) {
  if (su.isEmpty(text)) {
    return '';
  }

  // We need to double encode the string so that it reaches SU in encoded
  // form, otherwise SU automatically unencodes strings leading to incorrect
  // parsing if the attribute values contain ampersands or equals.
  var str = encodeURIComponent(text);

  // The javascript escape function does not escape + symbols, so do that
  // manually.
  str = str.replace(/\+/g, '%2B');

  return str;
};

/**
 * Takes an object of name/value pairs and converts it to a properly encoded
 * query string.
 * @param {string|Object} params An object whose keys and values should be
 *     formatted into a URL query string.
 * @return {string} The value after the set operation has completed.
 */
su.createQueryString = function(params) {
  var qs = '';
  for (var key in params) {
    var value = params[key];
    value = su.urlEncode(value);
    qs += key + '=' + value + '&';
  }

  return qs.slice(0, -1);
};

/**
 * Returns a sanitized version of aString, meaning any embedded script tags
 * and similarly risky elements have been removed.
 * @param {string} aString The HTML string to sanitize.
 * @return {string} A nice shiny HTML string.
 */
su.sanitizeHTML = function(aString) {

  var str = aString.toString();

  // Strip out null.
  str = str.replace(/\[0x00\]/gmi, '');

  // Strip out carriage returns and other control characters.
  str = str.replace(/(&#x0D;|&#x0A;|&#x09;|&#9;)/gmi, '');
  str = str.replace(/(&#10;|&#16;|\t|\n|\r)/gmi, '');

  // Strip out tags that do not close.
  str = str.replace(/<[^>]*$/gmi, '');

  // Strip out tags that do not open.
  str = str.replace(/^[^<]*>/gmi, '');

  // Check all instances of HTML tags. Only if they match our very limited
  // white list will they be allowed through.
  return str.replace(/<[^>]*>/gmi, function(match) {
      // If there are *any* style or javascript strings inside the tag,
      // then strip it. Also, look for any open parenthesis (escaped or
      // unescaped), curly braces, or square backets, since simple link URLs
      // will not contain these whereas javascript will.
      var containsStyleRegex = new RegExp('style\s*|\\(|&#41;|<.*<' +
          '|script:|file:|ftp:|&#040|\{|\}|\[|\]|%5B|%5D|%3C|%3E|&#x28;',
          'img');
      if (containsStyleRegex.test(match) == true) {
        return '';
      }

      // If it's an http: or https: link or a font tag, then let it through.
      var isLinkOrFontRegex = new RegExp('^<\/*(a href=("|&quot;)http|font)',
          'img');
      if (isLinkOrFontRegex.test(match) == true) {
        // If there is any attribute that starts with "on", then strip the
        // tag, since this could be a binding to a JS event.
        var containsJSBinding = new RegExp('on\\S*\\s*=','img');
        if (containsJSBinding.test(match) == true) {
          return '';
        } else {
          return match;
        }
      }

      // Finally, only allow it if it's in our explicit white list.
      var whiteListRegEx = new RegExp('^</*' +
          '(b|i|u|strong|em|p|br|ol|ul|li|a)/*>$', 'img');
      if (whiteListRegEx.test(match) == true) {
        return match;
      } else {
        return '';
      }

    });
};

//  --------------------------------------------------------------------------
//  Key/Value Management
//  --------------------------------------------------------------------------

/**
 * Returns an Array of the items in the object in key/value Array pairs.
 * @param {Object} anObject The object whose items you want to acquire.
 * @return {Array} The list of keys/value pairs in the target object.
 */
su.getItems = function(anObject) {
  var arr = [];
  for (var i in anObject) {
    arr.push([i, anObject[i]]);
  }
  return arr;
};

/**
 * Returns an Array of the keys in the object.
 * @param {Object} anObject The object whose keys you want to acquire.
 * @return {Array} The list of keys in the target object.
 */
su.getKeys = function(anObject) {
  var arr = [];
  for (var i in anObject) {
    arr.push(i);
  }
  return arr;
};

/**
 * Returns an Array of the values in the object.
 * @param {object} anObject The object whose values you want to acquire.
 * @return {Array} The list of values in the target object.
 */
su.getValues = function(anObject) {
  var arr = [];
  for (var i in anObject) {
    arr.push(anObject[i]);
  }
  return arr;
};

//  --------------------------------------------------------------------------
//  Selection Management
//  --------------------------------------------------------------------------

/**
 * Returns the string value of an element's current selected text. If no
 * element or ID is provided then the current active element is used.
 * @param {string|Element} elementOrID The element or element ID to find.
 * @return {string} The selection string value.
 */
su.getTextSelection = function(elementOrID) {
  var el;
  var selection;
  var text;

  if (su.notEmpty(elementOrID)) {
    el = $(elementOrID);
  } else {
    el = document.activeElement;
  }

  //  if the element isn't the active element then we aren't looking in the
  //  same place and the selection in that element is empty.
  if (!el || (el != document.activeElement)) {
    return '';
  }

  if (su.IS_MAC) {
    text = el.value.substring(el.selectionStart, el.selectionEnd);
  } else {
    if (su.isValid(selection = document.selection)) {
      text = selection.createRange().text;
    }
  }

  return text || '';
};

/**
 * Replaces the current selection in a text field or text area with the text
 * provided.
 * @param {string|Element} elementOrID The element or element ID to find.
 * @param {string} text The new text to replace/insert.
 * @param {string} textRangeToReplace Optional. An explicit range to replace.
 */
su.replaceSelection = function(elementOrID, text, textRangeToReplace) {
  var el = $(elementOrID)
  if (su.notValid(el)) {
    return;
  }

  if (su.IS_MAC) {
    if (su.isValid(el.selectionStart)) {
      var start = el.selectionStart;
      var end = el.selectionEnd;
      el.value = el.value.substr(0, start) + (text || '') +
        el.value.substr(end);
      el.selectionStart = start + text.length;
      el.selectionEnd = start + text.length;
    }
  } else {
    if (su.isValid(textRangeToReplace)) {
      el.focus();
      textRangeToReplace.text = text;
    } else {
      el.focus();
      var sel = document.selection.createRange();
      sel.text = text;
    }
  }
};

/**
 * Sets the current selection in a text field or text area to the range of
 * indexes provided.
 * @param {string|Element} elementOrID The element or element ID to find.
 * @param {number} startIndex The starting index from 0 to the field length.
 * @param {number} endIndex The ending index from 0 to the field length.
 */
su.selectFromTo = function(elementOrID, startIndex, endIndex) {
  var el = $(elementOrID);
  if (su.notValid(el)) {
    // Note that the $() function will raise InvalidParameter here, so all
    // we need to do is return.
    return;
  }

  // Normalize the indexes so they relate to the text content. Both start
  // and end must be greater than or equal to 0 and less than or equal to
  // the field length. End must be after, or equal to, the start.
  var start = Math.max(startIndex || 0, 0);
  var end = Math.max(endIndex || 0, 0);
  var len = el.value.length;
  start = Math.min(start, len);
  end = Math.min(end, len);
  end = Math.max(end, start);

  if (su.IS_MAC) {
    el.setSelectionRange(start, end);
  } else {
    var range = el.createTextRange();
    if (su.isValid(range)) {
      range.collapse(true);
      range.moveStart('character', start);
      range.moveEnd('character', end - start);
      range.select();
    }
  }
};

//  --------------------------------------------------------------------------
//  Status Information
//  --------------------------------------------------------------------------

/**
 * Updates the su.IS_ONLINE flag by calling SketchUp and then invokes the
 * named callback function if the online status is false.
 * @param {string} callback The name of the function to call if offline.
 */
su.ifOffline = function(callback) {
  if (!su.isString(callback)) {
    su.raise(su.translateString('InvalidParameter'));
    return;
  }

  su.callRuby('is_online', {'onsuccess': 'su.handleOnlineUpdate_',
    'oncomplete': 'su.handleIsOffline_',
    'callback': callback});
};

/**
 * Updates the su.IS_ONLINE flag by calling SketchUp and then invokes the
 * named callback function if the online status is true.
 * @param {string} callback The name of the function to call if online.
 */
su.ifOnline = function(callback) {
  if (!su.isString(callback)) {
    su.raise(su.translateString('InvalidParameter'));
    return;
  }

  su.callRuby('is_online', {'onsuccess': 'su.handleOnlineUpdate_',
    'oncomplete': 'su.handleIsOnline_',
    'callback': callback});
};

/**
 * Responds to notifications from the is_online Ruby call regarding online
 * status. The resulting value is stored in the su.IS_ONLINE flag for
 * reference.
 * @param {string} queryid The ID of the query used to query online state.
 * @private
 */
su.handleOnlineUpdate_ = function(queryid) {
  var obj = su.getRubyResponse(queryid);
  if (su.isValid(obj)) {
    su.IS_ONLINE = obj['online'];
  }
};

/**
 * Responds to notifications that SketchUp has network connectivity.
 * @param {string} queryid The ID of the query used to query online state.
 * @private
 */
su.handleIsOnline_ = function(queryid) {
  var request = su.getRubyRequest(queryid);
  if (su.isValid(request)) {
    var callback = request['callback'];
    if (su.notEmpty(callback)) {
      var obj = su.resolveObjectPath(callback);
      if (su.isFunction(obj)) {
        obj(queryid);
      }
    }
  }
};

//  --------------------------------------------------------------------------
//  Window Management
//  --------------------------------------------------------------------------

/**
 * Sets the 'top', 'left', 'width', and 'height' properties of the current
 * dialog running the code. An optional 'dialog' key can supply the desired
 * dialog name.
 * @param {object} params   An object whose keys should include top/left
 *                          and width/height pairs as needed to configure the
 *                          size and position of the dialog.
 */
su.setDialogProperties = function(params) {
  su.callRuby('set_dialog_properties', params);
  return;
};

//  --------------------------------------------------------------------------
//  Ruby/JavaScript "Bridge"
//  --------------------------------------------------------------------------

// The Ruby and JavaScript code in SketchUp communicates asynchronously via
// what we call the "ruby/js bridge", a set of coordinated functions in Ruby
// and JavaScript which consumers use to invoke Ruby from JavaScript and
// receive callback notifications and response/fault data.
//
// The public JS functions are su.callRuby, su.getRubyResponse,
// and su.getRubyFault. In addition, when making calls via the
// su.callRuby method a JavaScript developer can provide onsuccess,
// onfailure, and oncomplete keys which provide the names of JavaScript
// functions to invoke when the Ruby is complete, succeeded, or failed. The
// oncomplete hook, if provided, is always called regardless of success or
// failure.
//
// The remainer of the functions here are invoked via Ruby and shouldn't
// normally be invoked by JavaScript code. See the js_callback routine in Ruby
// for more information on how Ruby communicates with JavaScript oncomplete.

//  --------------------------------------------------------------------------

/**
 * Constant defining the key used to store fault data from a Ruby call.
 * @type {string}
 */
su.RUBY_FAULT = 'fault';

/**
 * Constant defining the key used for Ruby query data.
 * @type {string}
 */
su.RUBY_QUERY = 'query';

/**
 * Constant defining the key used to identify a specific Ruby query.
 * @type {string}
 */
su.RUBY_REQUEST = 'request';

/**
 * Constant defining the key used to store response data from a Ruby call.
 * @type {string}
 */
su.RUBY_RESPONSE = 'response';

/**
 * Container for all callback data cached for the Ruby/JS bridge.
 * @type {Object}
 * @private
 */
su.rubyCallData_ = {};

/**
 * The name of the last Ruby function invoked.
 * @type {string?}
 * @private
 */
su.rubyLastCall_ = null;

//  --------------------------------------------------------------------------

/**
 * Invokes a function in Ruby defined as part of the SketchUp Ruby API or as
 * part of an included/required Ruby module. Note that this call is made in
 * an asynchronous fashion. Callbacks to the JavaScript are dependent on the
 * Ruby function being invoked. See SketchUp's js_callback Ruby method for
 * more information on how to return results to the invoking JavaScript.
 * @param {string} funcname The name of the Ruby function to invoke.
 * @param {string|Object} opt_request A pre-formatted URL-style query string
 *     or an object whose keys and values should be formatted into a URL
 *     query string.
 */
su.callRuby = function(funcname, opt_request) {
  var query;

  if (su.isEmpty(funcname)) {
    return;
  }

  // Create a unique ID for this particular call (as long as we don't call
  // the same function within the ms clock threshold these will be unique).
  var queryid = funcname + '_' + (new Date()).getTime();

  // Save the original request object itself, without alteration.
  su.setRubyRequest_(queryid, opt_request);

  // Construct a viable query string version of the request data.
  if (su.isString(opt_request)) {
    query = opt_request;
  } else if (su.isValid(opt_request)) {
    query = su.createQueryString(opt_request);
  }
  su.setRubyQuery_(queryid, query);

  // Build an element we can access from the Ruby side to get the data.
  try {
    var elem = document.createElement('input');
    elem.setAttribute('type', 'hidden');
    elem.setAttribute('id', queryid);
    elem.setAttribute('style', 'display:none');
    elem.value = query;
    document.body.appendChild(elem);
  } catch (e) {
    // If the element version fails we have to fall back to passing via the
    // normal query string approach. We'll signify that by leaving queryid
    // empty and appending the original query string.
    queryid = '&' + query;
  }

  // Note the use of a non-standard scheme here. This is installed by
  // SketchUp when it embeds the browser, allowing it to intercept all skp:
  // prefixed URIs and to route them to the Ruby SketchUp interface.
  var url = 'skp:' + funcname;
  url += '@queryid=' + queryid;

  su.rubyLastCall_ = queryid;
  su.setLocation(url);
};

/**
 * Sets the current location to the URI provided.
 * @param {string} url The url to set as the current location href.
 */
su.setLocation = function(url) {
  // Actual call is made here by setting location to our skp: url but we do
  // that in a setTimeout to force a flush of the DOM before Ruby invocation.
  window.setTimeout(function() {
    window.location.href = url;
  }, 0);
};

/**
 * Stores a value to the document's cookie using the name supplied.
 * @param {string} name The name to store the value under.
 * @param {string} value The value to store the value under.
 */
su.storeToCookie = function(name, value) {
  var cookies = document.cookie;
  var newCookies;

  // Pull apart the cookie, capturing the value for the named key up through
  // the terminating semi-colon or the end of the string.
  var cookieRegex = new RegExp('(.*)' + name + '=(.+?)(;|$)');

  if (cookieRegex.test(cookies) == true) {
    newCookies = cookies.replace(cookieRegex,
     '$1' + name + '=' + value + ';$3');
  } else {
    newCookies = name + '=' + value + ';' + cookies;
  }

  document.cookie = newCookies;
};

/**
 * Retrieves a value from the document's cookie using the name supplied.
 * @param {string} name The name to retrieve the value from.
 * @return {string} The cookie value stored under the name key provided.
 */
su.retrieveFromCookie = function(name) {
  var cookies = document.cookie;

  var cookieRegex = new RegExp('(.*)' + name + '=(.+?)(;|$)');

  if (cookieRegex.test(cookies) == true) {
    return cookies.match(cookieRegex)[2];
  }

  return null;
};

/**
 * Called by Ruby to clear Ruby/JS bridge callback data values so that no
 * callback data is left over from a prior call. You should never need to
 * call this method from JavaScript.
 * @param {string} queryid The unique ID of the Ruby function invocation
 *     whose data should be cleared.
 * @private
 */
su.clearRubyData_ = function(queryid) {
  var name = queryid || su.rubyLastCall_;
  try {
    var elem = $(name);
    if (su.isValid(elem)) {
      elem.parentNode.removeChild(elem);
    }
  } catch (e) {
  } finally {
    // Remove the data structures for the call in question.
    delete su.rubyCallData_[name];
  }
};

/**
 * Returns a particular piece of data returned from the last callRuby call.
 * If a queryid is provided then the return value is specific to that Ruby
 * function invocation.
 * @param {string} queryid The unique ID of the invocation whose results
 *     we're interested in. Default is the last call.
 * @param {string} key The specific data key being requested. This is
 *     commonly either su.RUBY_FAULT or su.RUBY_RESPONSE.
 * @return {Object?} Response data from the last callRuby invocation.
 * @private
 */
su.getRubyData_ = function(queryid, key) {
  var name = queryid || su.rubyLastCall_;
  var data = su.rubyCallData_[name];

  if (su.isValid(data)) {
    if (su.isEmpty(key)) {
      return data;
    }

    var obj = data[key];
    if (su.isString(obj) && su.notEmpty(obj)) {
      try {
        var str = obj.replace(/\n/gi, '\\n');
        str = str.replace(/^\s(.*)\s$/, '$1');
        if ((/^\{(?:.*)\}$/).test(str)) {
          str = str.replace(/\%22/gi, '"');
          str = str.replace(/&quot;/gi, '"');
          str = str.replace(/&apos;/gi, '\'');
          str = str.replace(/&#39;/gi, '\'');
        } else {
          str = str.replace(/\%22/gi, '&quot;');
        }
        obj = eval('(' + str + ')');
      } catch (e) {
        // If the string looks like it was intended to be valid JSON then
        // we'll notify via warning that an apparent parser error happened.
        if ((/^\{(?:.*)\}$/).test(str)) {
          su.log(su.translateString('WARNING: Unable to parse: ') + str);
        }
        // In either case we return the original string and let the requestor
        // deal with any fallout since at least it retains debugg-ability.
        obj = data[key];
      }
    }
  }

  return obj;
};

/**
 * Returns any fault object returned from the last callRuby invocation. If
 * a queryid is provided then the return value is specific to that Ruby
 * function invocation.
 * @param {string} queryid The unique ID of the invocation whose results
 *     we're interested in. Default is the last call.
 * @return {Object?} Fault data from the last callRuby invocation.
 */
su.getRubyFault = function(queryid) {
  return su.getRubyData_(queryid, su.RUBY_FAULT);
};

/**
 * Returns any query string used during the last callRuby invocation. If a
 * queryid is provided then the return value is specific to that Ruby function
 * invocation.
 * @param {string} queryid The unique ID of the invocation whose results
 *     we're interested in. Default is the last call.
 * @return {string?} The query string from the last callRuby invocation.
 */
su.getRubyQuery = function(queryid) {
  return su.getRubyData_(queryid, su.RUBY_QUERY);
};

/**
 * Returns any query request object used during the last callRuby invocation.
 * If a queryid is provided then the return value is specific to that Ruby
 * function invocation.
 * @param {string} queryid The unique ID of the invocation whose results
 *     we're interested in. Default is the last call.
 * @return {Object?} Request data from the last callRuby invocation.
 */
su.getRubyRequest = function(queryid) {
  return su.getRubyData_(queryid, su.RUBY_REQUEST);
};

/**
 * Returns a result object constructed from the return value from the last
 * callRuby invocation. If a queryid is provided then the response data is
 * specific to that Ruby function invocation.
 * @param {string} queryid The unique ID of the invocation whose results
 *     we're interested in. Default is the last call.
 * @return {Object?} Response data from the last callRuby invocation.
 */
su.getRubyResponse = function(queryid) {
  return su.getRubyData_(queryid, su.RUBY_RESPONSE);
};

/**
 * The primary callback entry point from Ruby back into JavaScript. This
 * method is invoked from Ruby to provide common error trapping and logging
 * functionality around all JS callbacks.
 * @param {string} callback The name of the callback function to invoke.
 * @param {string} queryid The unique ID of the originating function the
 *     callback was registered for.
 * @private
 */
su.rubyCallback_ = function(callback, queryid) {
  // Find the function reference, dealing with namespaces as needed.
  var obj = su.resolveObjectPath(callback);
  if (su.isFunction(obj) != true) {
    su.raise(su.translateString('Missing callback function: ') + callback);
      return;
    }

  try {
    if (!su.isFunction(obj)) {
      su.raise(su.translateString('Missing callback function: ') + callback);
      return;
    }
    obj(queryid);
  } catch (e) {
    su.raise(su.translateString('Callback function error: ') + e.message);
  }
};

/**
 * Updates a Ruby/JS bridge field using the key and value provided. This
 * method is invoked by other Ruby-initiated bridge methods. You should
 * never need to call this method from JavaScript.
 * @param {string} queryid The unique ID of the invocation whose results
 *     are being set. Default is the last call.
 * @param {string} key The name of the key. This is commonly either
 *     su.RUBY_FAULT or su.RUBY_RESPONSE.
 * @param {Object} value The value to associate with the key.
 * @return {Object?} The value after the set operation has completed.
 * @private
 */
su.setRubyData_ = function(queryid, key, value) {
  var name = queryid || su.rubyLastCall_;
  var data = su.rubyCallData_[name];

  if (su.notValid(data)) {
    data = {};
    su.rubyCallData_[name] = data;
  }

  data[key] = value;

  return data[key];
};

/**
 * Called by Ruby to update the Ruby/JS bridge fault field value with a
 * unique fault code or identifier. When a fault is encountered in a Ruby
 * function this bridge method is invoked to pass that information back to
 * JavaScript. You should never need to call this method from JavaScript.
 * @param {string} queryid The unique ID of the invocation whose fault
 *     is being set. Default is the last call.
 * @param {string} value The fault identifier.
 * @return {Object?} The value after the set operation has completed.
 * @private
 */
su.setRubyFault_ = function(queryid, value) {
  return su.setRubyData_(queryid, su.RUBY_FAULT, value);
};

/**
 * Called by Ruby to update the Ruby/JS bridge query field value. When a
 * call is made across the bridge the actual query data is placed in the
 * query field rather than trying to pass it on the URL to avoid length
 * issues in different browsers.
 * @param {string} queryid The unique ID of the invocation whose query
 *     is being set. Default is the last call.
 * @param {string} value The query string content.
 * @return {Object?} The value after the set operation has completed.
 * @private
 */
su.setRubyQuery_ = function(queryid, value) {
  return su.setRubyData_(queryid, su.RUBY_QUERY, value);
};

/**
 * Called by Ruby to update the Ruby/JS bridge request object value with
 * request data from a callRuby method. Data in this field can be acquired
 * from the JavaScript side by invoking su.getRubyRequest(). You never call
 * this method from JavaScript.
 * @param {string} queryid The unique ID of the invocation whose request
 *     data is being set. Default is the last call.
 * @param {Object} value The request data. This is the object used to pass
 *     initial query parameter data to a callRuby function.
 * @return {Object?} The value after the set operation has completed.
 * @private
 */
su.setRubyRequest_ = function(queryid, value) {
  return su.setRubyData_(queryid, su.RUBY_REQUEST, value);
};

/**
 * Called by Ruby to update the Ruby/JS bridge response field value with
 * result data from a callRuby method. Data in this field can be acquired
 * from the JavaScript side by invoking su.getRubyResponse(). You never call
 * this method from JavaScript.
 * @param {string} queryid The unique ID of the invocation whose response
 *     data is being set. Default is the last call.
 * @param {string} value The response data. This is often provided as
 *     a JSON-formatted string.
 * @return {Object?} The value after the set operation has completed.
 * @private
 */
su.setRubyResponse_ = function(queryid, value) {
  return su.setRubyData_(queryid, su.RUBY_RESPONSE, value);
};

