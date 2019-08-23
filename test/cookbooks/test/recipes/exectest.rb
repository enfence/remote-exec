testfiles = [
  'foo',
  'bar',
  'should-not-exist',
  'input',
  'not-if-ok',
  'not-if-smoke',
  'only-if-ok',
]

testfiles.each do |f|
  file "/tmp/#{f}" do
    action :delete
  end
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
end

# Check that not_if_remote prevents execution and is executed remotely
remote_execute 'touch /tmp/should-not-exist' do
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

remote_execute 'touch /tmp/should-not-exist' do
  user 'testuser'
  password node['test-cookbook']['testuser']['password']
  address 'localhost'
  only_if_remote '/usr/local/bin/is-not-local-ssh'
end
