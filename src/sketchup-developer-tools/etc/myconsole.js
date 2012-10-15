// Copyright 2012 Trimble Navigation Ltd.

/**
 * @fileoverview A simple example of how to extend the Console shortcuts by
 * adding a custom user script. In this case we're building the JavaScript
 * side of an \echo command shortcut. The Ruby do_echo command is defined in
 * the sample myconsole.rb file.
 */

/**
 * Executes the echo command, echoing back whatever we type. The string to
 * echo is whatever follows '\echo' on the command line.
 * @param {string} aString The string to echo.
 */
console.exec_echo = function(aString) {
  su.callRuby('do_echo', 
      {'echo': aString,
      'oncomplete': 'console.handleEchoComplete'});
};

/**
 * Handles notifications that our echo command has completed. Here we're
 * demonstrating how to get information from the Ruby-JS bridge related to
 * the original request whose ID was 'queryid'.
 * @param {string} queryid The unique request ID this callback is for.
 */
console.handleEchoComplete = function(queryid) {

  // This is the standard way to get data back from a bridge call. The
  // callback function receives a unique queryid which it can use to match
  // up with the data in case multiple asynchronous calls were being done.
  var response = su.getRubyResponse(queryid); 

  // Play it safe, check to make sure we got a valid (not null/undefined)
  // response back from the Ruby side.
  if (su.notValid(response)) {
    response = '';
  }

  // In this case we just echo to the console via an append.
  console.appendContent(response);
};

