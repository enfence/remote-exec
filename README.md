# remote-exec cookbook

This cookbook implements the `remote_execute` resource. As its name implies, the
resource executes a command on a remote server using ssh.

## Requirements

* Chef 12 or higher
* Net::SSH Ruby module, as included with Chef

## Resources

### `remote_execute`

Syntax:

```ruby
remote_execute 'name' do
  address   String          #
  command   String          # defaults to name
  returns   Integer, Array  #
  password  String          #
  user      String          #
  timeout   Integer         # default: 60
  input     String          #

  not_if_remote   String    # Remotely executed shell guard command like not_if
  only_if_remote  String    # Remotely executed shell guard command like only_if

  action    Symbol          # defaults to :run
end
```

#### Actions

The resource has the following actions:

* `:nothing` Prevent a command from running. Does nothing ;-)

* `:run` Default. Run a command.

#### Properties

The resource has the following properties:

* `command`: The shell command line to execute. Default value: the `name` of the resource block

* `returns`: The return value for a command. This may be an array of accepted values. An exception is raised when the return value does not match. Default value: `0`.

* `address`: The address of the remote server.

* `user`: The username used to connect to the remote server. Defaults to the user name under which the chef-client is running.

* `password`: The password for the user to connect to the remote server. If not specified, Net::SSH tries to connect using SSH keys, and if it doesn't help, asks for a password.

* `timeout`: Timeout for SSH session. Default is 60 seconds.

* `input`: If given, the string will be sent as stdin to the command.

#### Guards

There are 2 additional guards, implemented in the resource:

* `not_if_remote`: It prevents a resource from executing, if the specified condition (command) returns on the remote server true (0).

* `only_if_remote`: It allows a resource to execute, only if the specified condition (command) returns on the remote server true (0).

Note: In contrast to the classic chef guards, these do not support blocks, since there is no sensible way to evaluate locally created blocks on a remote machine. Likewise, choosing a different guard interpreter or passing any other additional options to the guard is not supported either.

Note: The order in which not_if_remote and only_if_remote are executed is an implementation detail. Do not rely on side effects of either to be executed if you pass both.

Note: If both not_if_remote and only_if_remote are given, they *both* must allow execution for the resource to be executed.

#### Example

```ruby
remote_execute 'create a file' do
  command 'touch /tmp/tempfile'
  address '192.168.0.1'
  user 'root'
  password 'dontknow'
  only_if_remote 'ls /dev/null'
end
```

## ChangeLog

### v0.2.0 2017-02-18

- input option added

### v0.1.1 2016-11-28

- timeout option added

### v0.1.0 2016-11-07

- Initial release
