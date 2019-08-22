file '/tmp/foo' do
  action :delete
end

remote_execute 'touch /tmp/foo' do
  user 'testuser'
  password 'foobar2342'
  address 'localhost'
end
