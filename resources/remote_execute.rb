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

property :not_if_remote, [String, Array]
property :only_if_remote, [String, Array]

action :run do
  Chef::Log.debug('remote_execute.rb: action_run')

  allowed_exit_codes = if new_resource.returns.is_a?(Array)
                         new_resource.returns
                       else
                         [new_resource.returns]
                       end

  ssh_session do |session|
    if !new_resource.not_if_remote.nil? && !new_resource.not_if_remote.empty?
      break if eval_command(session, new_resource.not_if_remote)
    end
    if !new_resource.only_if_remote.nil? && !new_resource.only_if_remote.empty?
      break unless eval_command(session, new_resource.only_if_remote)
    end

    descriptor = "#{new_resource.command.inspect} on server #{new_resource.address.inspect} as #{new_resource.user.inspect}"
    converge_by("execute #{descriptor}") do
      r = ssh_exec(session, new_resource.command, input: new_resource.input)
      Chef::Log.debug("remote_execute.rb: action_run(#{new_resource.command}) "\
                      "return code #{r[2]}, "\
                      "stdout #{r[0]}, "\
                      "stderr #{r[1]}")
      # check return code?
      success = allowed_exit_codes.include?(r[2])
      unless success
        error_parts = [
          "Expected process to exit with #{allowed_exit_codes.inspect}, but received #{r[2]}",
        ]
        if new_resource.sensitive
          error_parts.push(
            'STDOUT/STDERR suppressed for sensitive resource'
          )
        else
          error_parts.push(
            "---- Begin output of #{descriptor} ----",
            "STDOUT: #{r[0]}",
            "STDERR: #{r[1]}",
            "---- End output of #{descriptor}----"
          )
        end
        raise error_parts.join("\n")
      end
    end
  end
end

action_class do
  def eval_command(session, command)
    rc = ssh_exec(session, command)
    Chef::Log.debug("eval_command: stdout: #{rc[0]}")
    Chef::Log.debug("eval_command: stderr: #{rc[1]}")
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

  def ssh_exec(session, command, input: nil)
    # Unfortunately, SSH does not allow passing an execv-like array and only
    # supports strings. So we have to do shell escaping and hope for the best...
    command = Shellwords.shelljoin(command) if command.is_a?(Array)

    stdout_data = ''
    stderr_data = ''
    exit_code = nil
    exit_signal = nil
    session.open_channel do |channel|
      channel.exec(command) do |_ch, success|
        abort "FAILED: couldn't execute command (ssh.channel.exec)" unless success
        channel.on_data { |_, data| stdout_data += data }
        channel.on_extended_data do |_, type, data|
          stderr_data += data if type == 1 # type 1 is stderr
        end
        channel.on_request('exit-status') { |_, data| exit_code = data.read_long }
        channel.on_request('exit-signal') { |_, data| exit_signal = data.read_long }
        unless input.nil?
          channel.send_data(input)
          channel.eof!
        end
      end
    end.wait
    [stdout_data, stderr_data, exit_code, exit_signal]
  end
end
