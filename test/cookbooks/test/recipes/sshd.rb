package 'openssh-server'

service 'sshd' do
  action :start
end

user 'testuser' do
  manage_home true
  password '$6$HE5ZpCQpxjHXxpDW$CNagQeQnHemlWpd9Lq77KIeZIOpz4zgy5wJA3njHP6bVEq0kYYJuZ4fqgm/fUL5/KFD.3jr.Xma5VCq1Zwe.k.'
end
