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
  address           String          #
  command           String, Array   # default: name
  returns           Integer, Array  #
  password          String          #
  user              String          #
  timeout           Integer         # default: 60
  input             String          #
  interactive       boolean         # default: false
  request_pty       boolean         # default: false
  sensitive         boolean         # default: false
  sensitive_command boolean         # default: sensitive
  sensitive_output  boolean         # default: sensitive
  live_stream       boolean         # default: false
  max_buffer_size   Integer         # default: 1 Mi (= 1048576)
  max_line_length   Integer         # default: 4 ki (= 4096)

  not_if_remote String, Array, Hash # Remotely executed shell guard command like not_if
  only_if_remote String, Array, Hash # Remotely executed shell guard command like only_if

  action    Symbol                  # default: :run
end
```

#### Actions

The resource has the following actions:

* `:nothing` Prevent a command from running. Does nothing ;-)

* `:run` Default. Run a command.

#### Properties

The resource has the following properties:

* `command`: default: `name` property

    - If `command` is a string, it is executed using the remote shell directly. This means that you need to pay attention to shell meta-characters such as space, quotes, dollar signs, semicolons etc. etc.. In general, you should avoid passing an interpolated string here.
    - If `command` is an array, the elements are shell-escaped using `Shellwords.escape` and then joined with spaces and treated as a string. Unfortunately, SSH requires a stringified command and does not support passing arrays.

* `returns`: The return value for a command. This may be an array of accepted values. An exception is raised when the return value does not match. Default value: `0`.

* `address`: The address of the remote server.

* `user`: The username used to connect to the remote server. Defaults to the user name under which the chef-client is running.

* `password`: The password for the user to connect to the remote server. If not specified, Net::SSH tries to connect using SSH keys, and if it doesn't help and `interactive` is set to true, asks for a password.

* `timeout`: Timeout for SSH session. Default is 60 seconds.

* `input`: If given, the string will be sent as stdin to the command.

* `interactive`: If true and a password is not given and password authentication is the only method left, Net::SSH will ask for a password on the terminal. Default: false.

* `request_pty`: Whether to allocate a pseudo-TTY device (PTY) for the command execution.

    If PTY allocation is requested but fails, an error is raised.

    **Warning:** PTYs are not binary-safe. For this reason, combining the
    `input` property with a `request_pty` value which enables TTY use for the
    command itself is prohibited and will lead to an error.

    **Note:** Using a PTY will merge the standard output and standard error
    streams of the executed command.

* `sensitive`: If true, `sensitive_output` and `sensitive_command` default to
  true instead of false.

* `sensitive_output` (default: `sensitive`). 

  If enabled for a command or guard (the same selection semantics as for
  `request_pty` apply), the standard output and standard error streams will not
  be printed, either directly or in error messages.

* `sensitive_command` (default: `sensitive`).

  If enabled for a command or guard (the same selection semantics as for
  `request_pty` apply), the commands will not be printed.

* `live_stream` (default: false): If true, the output of the main command is
  shown in real-time (except for line-buffering). This does not apply to guard
  commands (the output of guard commands is only in the debug log).

* `max_buffer_size`: Restrict the maximum number of codepoints in the Ruby
  string to buffer for non-streaming commands. If the number is exceeded, older
  data will be discarded (but the resource will continue to execute).

  Setting this can cause:

  - Memory exhaustion (obviously)
  - High CPU use if the remote command exceeds the limit, since the ringbuffer
    is not implemented very cleverly.

  Note: This limit is a soft limit and may be (temporarily) exceeded by an
  amount equal to the buffer size of the network stack.

* `max_line_length`: The maximum length of a single line for streamed output.
  If the line length is exceeded, the line is emitted as if it had been ended.
  No *data* is lost, but ambiguity about line breaks is introduced.

  Note: This limit is a soft limit and may be exceeded by an amount equal to
  the buffer size of the network stack.


#### Guards

##### Synopsis

The guards can either take a string, an array or a hash. The hash supports the
following keys:

```ruby
{
    command: [String, Array],
    request_pty: [TrueClass, FalseClass],  # default: false
    sensitive_output: [TrueClass, FalseClass],  # default: sensitive
    sensitive_command: [TrueClass, FalseClass]  # default: sensitive
}
```

If a string or array is given instead of a hash, the `value` is converted to
`{command: value}`.

* `command`: The command executed as guard. See the properties above for
  details.
* `request_pty`: Whether to request a PTY for the guard execution. See the
  properties above for details on the implications of requesting a PTY.
* `sensitive_output`: Whether to suppress printing the output of the guard
  command. The default is true if the resource is marked as sensitive, false
  otherwise.
* `sensitive_command`: Whether to suppress printing the guard command itself.
  The default is true if the resource is marked as sensitive, false otherwise.

##### Description

There are 2 additional guards, implemented in the resource:

* `not_if_remote`: It prevents a resource from executing, if the specified condition (command) returns on the remote server true (0).

* `only_if_remote`: It allows a resource to execute, only if the specified condition (command) returns on the remote server true (0).

The evaluation of the guards uses the same mechanism as `command`, so you can use either an Array or a String as command.

Note: In contrast to the classic chef guards, these do not support blocks, since there is no sensible way to evaluate locally created blocks on a remote machine. Likewise, choosing a different guard interpreter is not supported either. Additional options are supported as described above.

Note: The order in which not_if_remote and only_if_remote are executed is an implementation detail. Do not rely on side effects of either to be executed if you pass both.

Note: If both not_if_remote and only_if_remote are given, they *both* must allow execution for the resource to be executed.

#### Example

```ruby
remote_execute 'create a file' do
  command 'touch /tmp/tempfile'
  address '192.168.0.1'
  user 'root'
  password 'dontknow'
  only_if_remote command: 'ls /dev/null', request_pty: false
end
```

## ChangeLog

### v0.2.0 2017-02-18

- input option added

### v0.1.1 2016-11-28

- timeout option added

### v0.1.0 2016-11-07

- Initial release
