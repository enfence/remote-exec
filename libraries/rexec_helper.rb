
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

# RemoteExecute helper module
module RemoteExecute
  def re_only_if(cmd)
    Chef::Log.debug("re_only_if: #{cmd}")
    begin
      rc = runcmd(cmd)
      Chef::Log.debug("stdout: #{rc[0]}")
      Chef::Log.debug("stderr: #{rc[1]}")
      return true if rc[2] == 0
    rescue
      return false
    end
    false
  end

  def re_not_if(cmd)
    Chef::Log.debug("re_not_if: #{cmd}")
    begin
      rc = runcmd(cmd)
      Chef::Log.debug("stdout: #{rc[0]}")
      Chef::Log.debug("stderr: #{rc[1]}")
      return true if rc[2] == 0
    rescue
      return false
    end
    false
  end

  def runcmd(cmd)
    stdout_data = ''
    stderr_data = ''
    exit_code = nil
    exit_signal = nil
    Net::SSH.start(address, user, :password => password, :timeout => timeout) do |ssh|
      ssh.open_channel do |channel|
        channel.exec(cmd) do |_, success|
          abort "FAILED: couldn't execute command (ssh.channel.exec)" unless success
          channel.on_data { |_, data| stdout_data += data }
          channel.on_extended_data { |_, data| stderr_data += data }
          channel.on_request('exit-status') { |_, data| exit_code = data.read_long }
          channel.on_request('exit-signal') { |_, data| exit_signal = data.read_long }
          unless input.nil?
            channel.send_data(input)
            channel.eof!
          end
        end
      end
      ssh.loop
    end
    [stdout_data, stderr_data, exit_code, exit_signal]
  end
end
