#!/usr/bin/ruby -w
#
# Copyright:: Copyright 2012 Trimble Navigation Ltd.
# License:: Apache License, Version 2.0
#
# Sample startup file. The example here shows how you can use :userrb to
# extend the callbacks available to your console. You may choose to do this
# so you can match up Ruby-side hooks with command shortcuts in the Console
# added by your usersrc JavaScript file (presuming you defined one). That's
# what we're doing in this example, building the Ruby side of an \echo
# command shortcut.

# Open the Developer module.
module Developer

# Open the Console class.
class Console

  # Define an echo command as an example. Note that we don't have to do
  # anything else for callback methods as long as they start with do_. The
  # console will automatically register callbacks with this naming pattern. 
  #
  def do_echo(dialog, data)
    params = Bridge.query_to_hash(dialog, data)
    echo = 'echoing: ' + params['echo']

    # Call back to the JavaScript side, passing along what we received.
    Bridge.js_callback(dialog, 'do_echo', data, echo, false);
  end

end # Close the Console class.

end # Close the Developer module.

