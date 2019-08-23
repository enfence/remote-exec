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

include RemoteExecute

resource_name :remote_execute
default_action :run

property :command, String, name_property: true, required: true
property :returns, [Integer, Array]
property :timeout, Integer, default: 60
property :user, String
property :password, String
property :address, String, required: true
property :input, String

property :not_if_remote, String
property :only_if_remote, String

action :run do
  Chef::Log.debug('remote_execute.rb: action_run')
  really_run = true
  if really_run && !new_resource.not_if_remote.nil? && !new_resource.not_if_remote.empty?
    really_run = re_not_if(new_resource.not_if_remote) == false
  end
  if really_run && !new_resource.only_if_remote.nil? && !new_resource.only_if_remote.empty?
    really_run = re_only_if(new_resource.only_if_remote) == true
  end
  converge_by("Executing #{new_resource.command} on server #{new_resource.address} as #{new_resource.user}") do
    r = runcmd(new_resource.command)
    Chef::Log.debug("remote_execute.rb: action_run(#{new_resource.command}) "\
                    "return code #{r[2]}, "\
                    "stdout #{r[0]}, "\
                    "stderr #{r[1]}")
    # check return code?
    if property_is_set?(:returns)
      if new_resource.returns.is_a?(Array)
        raise r[1] unless new_resource.returns.include?(r[2])
      else
        raise r[1] unless r[2] == new_resource.returns
      end
    else
      raise r[1] unless r[2] == 0
    end
  end if really_run
end

action :nothing do
  nil
end
