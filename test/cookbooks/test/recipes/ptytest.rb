# Check if PTY allocation for the command works

remote_execute 'PTY positive true' do
  command 'test -t 0'
  request_pty true
  user 'testuser'
  password node['test-cookbook']['testuser']['password']
  address 'localhost'
end

remote_execute 'PTY negative true' do
  command 'test ! -t 0'
  request_pty true
  user 'testuser'
  password node['test-cookbook']['testuser']['password']
  address 'localhost'
  returns 1
end

remote_execute 'PTY positive default' do
  command 'test ! -t 0'
  user 'testuser'
  password node['test-cookbook']['testuser']['password']
  address 'localhost'
end

remote_execute 'PTY negative default' do
  command 'test -t 0'
  user 'testuser'
  password node['test-cookbook']['testuser']['password']
  address 'localhost'
  returns 1
end

# Check if PTY allocation for not_if_remote works

remote_execute 'not_if_remote PTY positive true' do
  # make the command fail if it is executed
  command 'false'
  request_pty true
  user 'testuser'
  password node['test-cookbook']['testuser']['password']
  address 'localhost'
  not_if_remote command: 'test -t 0', request_pty: true
end

remote_execute 'not_if_remote PTY positive :guards' do
  # make the command fail if it is executed
  command 'false'
  user 'testuser'
  password node['test-cookbook']['testuser']['password']
  address 'localhost'
  not_if_remote command: 'test -t 0', request_pty: true
end

remote_execute 'not_if_remote PTY negative :command' do
  # make the command fail if it is executed
  command 'false'
  request_pty true
  user 'testuser'
  password node['test-cookbook']['testuser']['password']
  address 'localhost'
  not_if_remote command: 'test ! -t 0', request_pty: false
end

remote_execute 'not_if_remote PTY negative default' do
  # make the command fail if it is executed
  command 'false'
  user 'testuser'
  password node['test-cookbook']['testuser']['password']
  address 'localhost'
  not_if_remote command: 'test ! -t 0', request_pty: false
end

# Check if PTY allocation for only_if_remote works

remote_execute 'only_if_remote PTY positive true' do
  # make the command fail if it is executed
  command 'false'
  request_pty true
  user 'testuser'
  password node['test-cookbook']['testuser']['password']
  address 'localhost'
  only_if_remote command: 'test ! -t 0', request_pty: true
end

remote_execute 'only_if_remote PTY positive :guards' do
  # make the command fail if it is executed
  command 'false'
  user 'testuser'
  password node['test-cookbook']['testuser']['password']
  address 'localhost'
  only_if_remote command: 'test ! -t 0', request_pty: true
end

remote_execute 'only_if_remote PTY negative :command' do
  # make the command fail if it is executed
  command 'false'
  request_pty true
  user 'testuser'
  password node['test-cookbook']['testuser']['password']
  address 'localhost'
  only_if_remote command: 'test -t 0', request_pty: false
end

remote_execute 'only_if_remote PTY negative default' do
  # make the command fail if it is executed
  command 'false'
  user 'testuser'
  password node['test-cookbook']['testuser']['password']
  address 'localhost'
  only_if_remote command: 'test -t 0', request_pty: false
end
