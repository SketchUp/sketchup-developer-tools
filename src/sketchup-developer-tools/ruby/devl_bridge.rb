#!/usr/bin/ruby -w
#
# Copyright:: Copyright 2012 Trimble Navigation Ltd.
# License:: Apache License, Version 2.0
#
# Ruby-to-JS (and back) "bridge" code.

require 'sketchup.rb'
require 'LangHandler.rb'

# Open the Developer module so our Bridge class can be accessible to other
# classes within that module more cleanly.
#
module Developer

# The Bridge class provide a number of class methods which allow a pair or
# Ruby and JavaScript functions to communicate. The JavaScript side of the
# bridge defines a set of callback functions on the 'su' (SketchUp) object
# which the Ruby side invokes when a Ruby action handler has completed.
#
class Bridge

  # General callback handler for all JS-to-Ruby invocations. This method
  # should be invoked as the last step in processing a JavaScript request in
  # an action handler method (usually starting with do_*. The key elements
  # to provide are the dialog and funcname which identify the calling dialog
  # and the function it was invoking as an action handler. These allow the
  # JavaScript to correlate results when they arrive.
  #
  # Standardized methods on the JavaScript side of the bridge should be
  # made available to this routine by including bridge.js or a suitable
  # replacement.
  #
  #
  # Args:
  # - dialog: UI:WebDialog, the WebDialog that made the original request.
  # - funcname: String, the invoking function name, passed back to JavaScript.
  # - query: String, the portion of the skp: URL after the @ sign.
  # - response: Object, the data that should be returned to the caller.
  # - fault: String|Number, a fault code, if any, when an error has occurred.
  #
  def self.js_callback(dialog, funcname, query, response, fault)

    # convert query string (a=b&c=d) into a hash of key value pairs
    hash = query_to_hash(dialog, query)
    queryid = hash['queryid'];

    # set/clear the fault data via the JS-side fault handler
    str = fault.nil? ? '' : fault.to_s.gsub('"','\"');
    if (fault != nil)
      script = 'su.setRubyFault_("' + queryid + '","' + str + '");'
      dialog.execute_script(script)
    end

    # set/clear the response data via the JS-side response handler
    str = response.nil? ? '' : response.gsub('"','\"');

    if (response != nil)
      script = 'su.setRubyResponse_("' + queryid + '","' + str + '");'
      dialog.execute_script(script)
    end

    # process whatever callbacks we might have been passed explicitly
    begin
      if (fault != nil)
        fname = hash['onfailure'] || hash['onFailure'];
        if (fname != nil)
          script = 'su.rubyCallback_("' + fname + '","' + queryid + '");'
          dialog.execute_script(script)
        end
      else
        fname = hash['onsuccess'] || hash['onSuccess'];
        if (fname != nil)
          script = 'su.rubyCallback_("' + fname + '","' + queryid + '");'
          dialog.execute_script(script)
        end
      end
    ensure
      fname = hash['oncomplete'] || hash['onComplete'];
      if (fname != nil)
        script = 'su.rubyCallback_("' + fname + '","' + queryid + '");'
        dialog.execute_script(script)
      end
    end

    script = 'su.clearRubyData_("' + queryid + '");'
    dialog.execute_script(script)
  end

  # General logging method allowing the JavaScript interface to send
  # messages to the Ruby console.
  #
  #
  # Args:
  # - dialog: UI:WebDialog, the WebDialog that made the original request.
  # - params:  a string containing the message content to be output in the
  #   message key, and optional separator, timestamp, and prefix keys
  #   defining a separator to output prior to outputting the log message as
  #   well as a timestamp and message prefix such as 'JS:'.
  #
  def self.js_log(dialog, params)

    # treat empty parameter as a request to output a blank line, just like a
    # call to puts without a parameter would do
    if (params == nil)
      puts
      return
    end

    # all other parameters should have come in key/value form so convert
    hash = query_to_hash(dialog, params)

    # optional separator can be output if provided. NOTE that even an empty
    # string can be used here to create a new (blank) line in the log
    if (hash['separator'] != nil)
      puts(hash['separator'])
    end

    # build up message text. should be timestamp prefix: message
    str = ''
    str += hash['timestamp'].to_s + ' ' unless hash['timestamp'] == nil
    str += hash['prefix'].to_s + ' ' unless hash['prefix'] == nil
    str += hash['message'].to_s unless hash['message'] == nil
    puts(str)

  end

  # Cleans up strings to inclusion inside JSON string values.
  #
  #
  # Args:
  # - value: String, a string that we want escaped for transmission in JSON.
  #
  # Returns:
  # - string: String, a JSON-friendly string for parsing in javascript.
  #
  def self.clean_for_json(value)
    value = value.to_s
    value = value.gsub(/\\/,'&#92;')
    value = value.gsub(/\"/,'&quot;')
    value = value.gsub(/\n/,'\n')
    if value.index(/e-\d\d\d/) == value.length-5
      value = "0.0";
    end
    return value
  end

  # Cleans up strings for inclusion inside XML structure. Replaces problematic
  # characters with their XML escaped version.
  #
  #
  # Args:
  # - value: String, a string that we want escaped for XML entities.
  #
  # Returns:
  # - string: String, an xml-friendly version suitable for embedding.
  def self.clean_for_xml(value)
    return 'nil' if value.nil?

    value = value.to_s
    value = value.gsub(/\&/,'&amp;')
    value = value.gsub(/\</,'&lt;')
    value = value.gsub(/\>/,'&gt;')
    value = value.gsub(/\"/,'&quot;')
    value = value.gsub(/\'/,'&#39;')
    return value
  end

  # URL-encode a string. Note the second parameter, which allows you to say
  # that you prefer the escape spaces (' ') with a plus character instead
  # of %20. This is significant because certain browsers have trouble with
  # one encoding vs. the other.
  #
  #   url_encoded_string = CGI::escape("'Stop!' said Fred")
  #      # => "%27Stop%21%27+said+Fred"
  #
  # Args:
  # - string: String, the string to encode.
  # - replace_spaces_with_plus: Boolean, should spaces be encoded via '+'?
  #   The default is true.
  #
  # Returns:
  # - string: String, the encoded string.
  #
  def self.escape(string, replace_spaces_with_plus=true)
    if replace_spaces_with_plus == true
      space_string = '+'
    else
      space_string = '%20'
    end
    if string != nil
      string = string.gsub(/([^ a-zA-Z0-9_.]+)/n) do
        '%' + $1.unpack('H2' * $1.size).join('%').upcase
      end.gsub(/ /, space_string)
    end
    return string
  end

  # URL-decode a string.
  #   string = CGI::unescape("%27Stop%21%27+said+Fred")
  #      # => "'Stop!' said Fred"
  #
  #
  # Args:
  # - string: String, the string to decode.
  #
  # Returns:
  # - string: String, the decoded string.
  #
  def self.unescape(string)
    if string != nil
      string = string.gsub(/\+/, ' ').gsub(/((?:%[0-9a-fA-F]{2})+)/n) do
        [$1.delete('%')].pack('H*')
      end
    end
    return string
  end

  # This method takes a query string and parses it into a hash with the same
  # name/value pairs as the query string
  #
  #     'Small=10&Medium=15&Really+Large=25'
  #
  # The above query string would be parsed into a hash like so...
  #
  #     hash['Small'] = '10'
  #     hash['Medium'] = '15'
  #     hash['Really Large'] = '25'
  #
  #
  # Args:
  # - query: String, a string with url encoded data, separated by '&'s.
  #
  # Returns:
  # - hash: Hash, the same data from the query string in hash form.
  #
  def self.query_to_hash(dialog, query)

    param_pairs = query.split('&')
    param_hash = {}
    for param in param_pairs
      name, value = param.split('=')
      name = unescape(name)
      value = unescape(value)
      param_hash[name] = value
    end

    # Ruby/JS Bridge uses queryid as the ID of an element containing the
    # real query data. In most cases the queryid will be the only parameter
    # but in either case this will overwrite any values with what's found in
    # the bridge's query element value
    query_id = param_hash['queryid']
    if (query_id != nil && query_id != '')
      query_str = dialog.get_element_value(query_id)
      param_pairs = query_str.split('&')
      for param in param_pairs
        name, value = param.split('=')
        name = unescape(name)
        value = unescape(value)
        param_hash[name] = value
      end
    end
    return param_hash
  end

end   # End of Developer::Bridge

end   # End of Developer module

