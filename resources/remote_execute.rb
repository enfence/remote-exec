# Copyright:: Copyright 2016, eNFence GmbH
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

resource_name :remote_execute
default_action :run

property :command, [String, Array], name_property: true, required: true
property :returns, [Integer, Array], default: [0]
property :timeout, Integer, default: 60
property :user, String
property :password, String, sensitive: true
property :address, String, required: true
property :input, String
property :interactive, [TrueClass, FalseClass], default: false
property :request_pty, [TrueClass, FalseClass], default: false
property :sensitive_output, [TrueClass, FalseClass], default: lazy { sensitive }
property :sensitive_command, [TrueClass, FalseClass], default: lazy { sensitive }
property :live_stream, [TrueClass, FalseClass], default: false
property :max_buffer_size, Integer, default: 1048576 # approx. 1 MiB
property :max_line_length, Integer, default: 4096 # 4 kiB

property :not_if_remote, [String, Array, Hash], coerce: proc { |v| RemoteExec::Validation.coerce_guard_config(v, sensitive) }, callbacks: RemoteExec::Validation.guard_config_checks
property :only_if_remote, [String, Array, Hash], coerce: proc { |v| RemoteExec::Validation.coerce_guard_config(v, sensitive) }, callbacks: RemoteExec::Validation.guard_config_checks

action :run do
  Chef::Log.debug('remote_execute.rb: action_run')

  allowed_exit_codes = if new_resource.returns.is_a?(Array)
                         new_resource.returns
                       else
                         [new_resource.returns]
                       end

  command_options = {
    input: new_resource.input,
    request_pty: new_resource.request_pty,
  }

  if !new_resource.input.nil? && command_options.fetch(:request_pty)
    # XXX: IF we ever allow input with PTYs, the .eof! method used below will
    # not work. Instead, we have to send double-\x04 (Ctrl+D a.k.a. End Of
    # Tranmission ASCII control code) to signal EOF. This is all super-fragile
    # which is why it is prohibited for now.
    raise 'PTY requested for command execution, but input is given. The options are incompatible, as PTYs are not binary-safe.'
  end

  ssh_session do |session|
    if !new_resource.not_if_remote.nil? && !new_resource.not_if_remote.empty?
      result = !eval_guard(session, new_resource.not_if_remote)
      Chef::Log.info("#{new_resource}: evaluated not_if_remote #{masked_command(new_resource.not_if_remote.fetch(:command).inspect, new_resource.not_if_remote.fetch(:sensitive_command))}. may proceed = #{result}")
      break unless result
    end
    if !new_resource.only_if_remote.nil? && !new_resource.only_if_remote.empty?
      result = eval_guard(session, new_resource.only_if_remote)
      Chef::Log.info("#{new_resource}: evaluated only_if_remote #{masked_command(new_resource.only_if_remote.fetch(:command).inspect, new_resource.only_if_remote.fetch(:sensitive_command))}. may proceed = #{result}")
      break unless result
    end

    descriptor = "#{masked_command(new_resource.command.inspect, new_resource.sensitive_command)} on server #{new_resource.address.inspect} as #{new_resource.user.inspect}"

    converge_by("execute #{descriptor}") do
      if new_resource.live_stream
        output_prefix = "[#{new_resource.address}] "
        nlines = 0
        exit_code, exit_signal = line_buffered_exec(session,
                                                    new_resource.command,
                                                    command_options) do |_stream, line|
          line << "\n" unless line.end_with?("\n")
          nlines += 1
          unless new_resource.sensitive_output
            # print an empty line before the first line for alignment, but only
            # if we actually receive output
            puts if nlines == 1
            # using print instead of puts, since line is forced to contain a \n
            # above.
            print "#{output_prefix}#{line}"
          end
        end

        if new_resource.sensitive_output
          puts "[#{fqdn}: #{nlines} line(s) of sensitive output suppressed (disable by setting sensitive_output to false or :guards)]"
        end

        stdout = nil
        stderr = nil
      else
        stdout, stderr, exit_code, exit_signal = ssh_exec(session,
                                                          new_resource.command,
                                                          command_options)
      end

      success = allowed_exit_codes.include?(exit_code)
      unless success
        error_parts = [
          "Expected process to exit with #{allowed_exit_codes.inspect}, but received #{exit_code} (signal: #{exit_signal})",
        ]
        if new_resource.sensitive_output
          error_parts.push(
            'STDOUT/STDERR suppressed for sensitive resource'
          )
        elsif !stdout.nil? || !stderr.nil?
          error_parts.push(
            "---- Begin output of #{descriptor} ----",
            "STDOUT: #{stdout}",
            "STDERR: #{stderr}",
            "---- End output of #{descriptor}----"
          )
        end
        raise error_parts.join("\n")
      end
    end
  end
end

action_class do
  def eval_guard(session, guard_command_config)
    guard_command_config = guard_command_config.dup
    command = guard_command_config.delete(:command)
    guard_command_config.delete(:sensitive_command)
    eval_command(session, command, guard_command_config)
  end

  def eval_command(session, command, sensitive_output: false, **options)
    rc = ssh_exec(session, command, options)
    unless sensitive_output
      Chef::Log.debug("eval_command: stdout: #{rc[0]}")
      Chef::Log.debug("eval_command: stderr: #{rc[1]}")
    end
    return true if rc[2] == 0
    false
  end

  def ssh_session
    retval = nil
    Net::SSH.start(new_resource.address,
                   new_resource.user,
                   password: new_resource.password,
                   timeout: new_resource.timeout,
                   non_interactive: !new_resource.interactive) do |session|
      retval = yield session
    end
    retval
  end

  def masked_command(command, sensitive)
    return '(suppressed sensitive command)' if sensitive
    command
  end

  def exec_io(session, command, input: nil, request_pty: false)
    # Unfortunately, SSH does not allow passing an execv-like array and only
    # supports strings. So we have to do shell escaping and hope for the best...
    command = Shellwords.shelljoin(command) if command.is_a?(Array)

    status_obj = {}
    session.open_channel do |channel|
      if request_pty
        channel.request_pty do |_ch, success|
          raise 'failed to allocate a requested PTY for command' unless success
        end
      end

      channel.exec(command) do |_ch, success|
        raise 'failed to execute command in channel' unless success

        channel.on_request('exit-status') do |_ch, data|
          status_obj[:exit_code] = data.read_long
        end
        channel.on_request('exit-signal') do |_ch, data|
          status_obj[:exit_signal] = data.read_long
        end

        channel.on_data do |ch2, data|
          yield ch2, :stdout, data
        end

        channel.on_extended_data do |ch2, type, data|
          yield ch2, :stderr, data if type == 1
        end

        channel.send_data(input) unless input.nil?
        # Always send EOF to prevent things from getting stuck unintentionally.
        channel.eof!
      end
    end.wait
    [status_obj[:exit_code], status_obj[:exit_signal]]
  end

  def extract_lines!(buffer)
    # note that this modifies buffer in-place for efficiency
    newline_pos = buffer.index("\n")
    until newline_pos.nil?
      line = buffer.slice!(0..newline_pos)
      yield line
      newline_pos = buffer.index("\n")
    end
    # maximum line length as anti-DoS measure
    # rubocop:disable Style/GuardClause
    if buffer.length >= new_resource.max_line_length
      yield buffer.dup
      buffer.clear
    end
    # rubocop:enable Style/GuardClause
  end

  def line_buffered_exec(session, command, options)
    # general idea: append data received via SSH to the respective buffers, and
    # flush the buffers to the passed block whenever a newline is encountered
    buffers = { stdout: '', stderr: '' }

    # FIXME: intelligently deal with ANSI escape codes like colour changes.
    exit_code, exit_signal = exec_io(session, command, options) do |_channel, stream, data|
      next unless buffers.key?(stream)
      buffer = buffers[stream]
      buffer << data
      extract_lines!(buffer) do |line|
        yield stream, line
      end
    end

    buffers.each_pair do |stream, remainder|
      next if remainder.empty?
      yield stream, remainder
    end

    [exit_code, exit_signal]
  end

  def append_ringbuffer!(buffer, data)
    buffer += data
    return unless buffer.length > new_resource.max_buffer_size
    to_cut = buffer.length - new_resource.max_buffer_size
    buffer.slice!(0..to_cut)
  end

  def ssh_exec(session, command, options)
    stdout_data = ''
    stderr_data = ''
    exit_code, exit_signal = exec_io(session,
                                     command,
                                     options) do |_channel, stream, data|
      append_ringbuffer!(stderr_data, data) if stream == :stderr
      append_ringbuffer!(stdout_data, data) if stream == :stdout
    end
    [stdout_data, stderr_data, exit_code, exit_signal]
  end
end
