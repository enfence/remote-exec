testfiles = [
  'foo',
  'bar',
  'should-not-exist',
  'input',
  'not-if-ok',
  'not-if-smoke',
  'only-if-ok',
  'notify-before',
  'notify-before-not_if_remote',
  'notify-before-only_if_remote',
  '$something',
]

testfiles.each do |f|
  file "/tmp/#{f}" do
    action :delete
  end
end

# this contains spaces to test the basic shell escaping
file '/tmp/guard target file' do
  action :create
end

cookbook_file '/usr/local/bin/is-local-ssh' do
  source 'is-local-ssh.sh'
  mode 0o755
  owner 'root'
  group 'root'
end

cookbook_file '/usr/local/bin/is-not-local-ssh' do
  source 'is-not-local-ssh.sh'
  mode 0o755
  owner 'root'
  group 'root'
end

# Create a file which is then tested for in the inspec tests.
remote_execute 'touch /tmp/foo' do
  user 'testuser'
  password node['test-cookbook']['testuser']['password']
  address 'localhost'
end

# Check that a non-zero exit status can be masked via array
remote_execute 'false' do
  user 'testuser'
  password node['test-cookbook']['testuser']['password']
  address 'localhost'
  returns [1]
end

# Check that a non-zero exit status can be masked via value
remote_execute 'false' do
  user 'testuser'
  password node['test-cookbook']['testuser']['password']
  address 'localhost'
  returns 1
end

# Check that input can be passed to the remote; the inspec test will check the
# contents
remote_execute 'tee /tmp/input' do
  user 'testuser'
  password node['test-cookbook']['testuser']['password']
  address 'localhost'
  input "some test input, even with funny characters like \" and '."
  live_stream true
end

# Check that not_if_remote prevents execution and is executed remotely
remote_execute 'not_if_remote test' do
  command 'touch /tmp/should-not-exist'
  user 'testuser'
  password node['test-cookbook']['testuser']['password']
  address 'localhost'
  not_if_remote '/usr/local/bin/is-local-ssh'
end

# This should be created, because the not_if script should only work on remote
# links.
remote_execute 'touch /tmp/not-if-smoke' do
  user 'testuser'
  password node['test-cookbook']['testuser']['password']
  address 'localhost'
  not_if '/usr/local/bin/is-local-ssh'
end

remote_execute 'touch /tmp/not-if-ok' do
  user 'testuser'
  password node['test-cookbook']['testuser']['password']
  address 'localhost'
  not_if_remote '/usr/local/bin/is-not-local-ssh'
end

remote_execute 'touch /tmp/only-if-ok' do
  user 'testuser'
  password node['test-cookbook']['testuser']['password']
  address 'localhost'
  only_if_remote '/usr/local/bin/is-local-ssh'
end

remote_execute 'only_if_remote test' do
  command 'touch /tmp/should-not-exist'
  user 'testuser'
  password node['test-cookbook']['testuser']['password']
  address 'localhost'
  only_if_remote '/usr/local/bin/is-not-local-ssh'
end

# Check that both not_if_remote and only_if_remote are taken into account

remote_execute 'not_if_remote plus only_if_remote test variant 1' do
  command 'touch /tmp/should-not-exist'
  user 'testuser'
  password node['test-cookbook']['testuser']['password']
  address 'localhost'
  not_if_remote 'true' # forbids execution
  only_if_remote 'true'  # allows execution
end

remote_execute 'not_if_remote plus only_if_remote test variant 2' do
  command 'touch /tmp/should-not-exist'
  user 'testuser'
  password node['test-cookbook']['testuser']['password']
  address 'localhost'
  not_if_remote 'false'  # allows execution
  only_if_remote 'false' # forbids execution
end

# Check that remote guard evaluation blocks notifications
remote_execute 'not_if_remote blocks following notifications' do
  command 'touch /tmp/should-not-exist'
  user 'testuser'
  address 'localhost'
  password node['test-cookbook']['testuser']['password']
  not_if_remote 'true'
  notifies :create, 'file[/tmp/should-not-exist]', :immediately
end

remote_execute 'only_if_remote blocks following notifications' do
  command 'touch /tmp/should-not-exist'
  user 'testuser'
  address 'localhost'
  password node['test-cookbook']['testuser']['password']
  only_if_remote 'false'
  notifies :create, 'file[/tmp/should-not-exist]', :immediately
end

remote_execute 'not_if_remote blocks before notifications' do
  command 'touch /tmp/should-not-exist'
  user 'testuser'
  address 'localhost'
  password node['test-cookbook']['testuser']['password']
  not_if_remote 'true'
  notifies :create, 'file[/tmp/should-not-exist]', :before
end

remote_execute 'only_if_remote blocks before notifications' do
  command 'touch /tmp/should-not-exist'
  user 'testuser'
  address 'localhost'
  password node['test-cookbook']['testuser']['password']
  only_if_remote 'false'
  notifies :create, 'file[/tmp/should-not-exist]', :before
end

# Check successful before notifications
remote_execute 'with before notification' do
  command 'test -f /tmp/notify-before'
  user 'testuser'
  address 'localhost'
  password node['test-cookbook']['testuser']['password']
  notifies :create, 'file[/tmp/notify-before]', :before
end

remote_execute 'only_if_remote with before notification' do
  command 'test -f /tmp/notify-before-only_if_remote'
  user 'testuser'
  address 'localhost'
  password node['test-cookbook']['testuser']['password']
  only_if_remote 'true'
  notifies :create, 'file[/tmp/notify-before-only_if_remote]', :before
end

remote_execute 'not_if_remote with before notification' do
  command 'test -f /tmp/notify-before-not_if_remote'
  user 'testuser'
  address 'localhost'
  password node['test-cookbook']['testuser']['password']
  not_if_remote 'false'
  notifies :create, 'file[/tmp/notify-before-not_if_remote]', :before
end

# Check that output on stderr does not break anything (#4)

remote_execute 'non-existant-command' do
  user 'testuser'
  password node['test-cookbook']['testuser']['password']
  address 'localhost'
  returns 127
end

# Check that action :nothing does nothing

remote_execute 'touch /tmp/should-not-exist' do
  action :nothing
  user 'testuser'
  password node['test-cookbook']['testuser']['password']
  address 'localhost'
end

# Check that arrays can be used as commands for safety against shells

remote_execute 'array command' do
  command ['touch', '/tmp/$something']
  user 'testuser'
  password node['test-cookbook']['testuser']['password']
  address 'localhost'
end

remote_execute 'array only_if_remote guard' do
  command ['touch', '/tmp/should-not-exist']
  user 'testuser'
  password node['test-cookbook']['testuser']['password']
  address 'localhost'
  only_if_remote ['test', '!', '-f', '/tmp/guard target file']
end

remote_execute 'array not_if_remote guard' do
  command ['touch', '/tmp/should-not-exist']
  user 'testuser'
  password node['test-cookbook']['testuser']['password']
  address 'localhost'
  not_if_remote ['test', '-f', '/tmp/guard target file']
end

remote_execute 'array only_if_remote guard' do
  command ['touch', '/tmp/only-if-array']
  user 'testuser'
  password node['test-cookbook']['testuser']['password']
  address 'localhost'
  only_if_remote ['test', '-f', '/tmp/guard target file']
end

remote_execute 'array not_if_remote guard' do
  command ['touch', '/tmp/not-if-array']
  user 'testuser'
  password node['test-cookbook']['testuser']['password']
  address 'localhost'
  not_if_remote ['test', '!', '-f', '/tmp/guard target file']
end

include_recipe 'test::ptytest'

# Check that EOF is always sent. The following resource would timeout otherwise.
remote_execute 'cat' do
  user 'testuser'
  password node['test-cookbook']['testuser']['password']
  address 'localhost'
end
