describe file('/tmp/foo') do
  it { should exist }
end

describe file('/tmp/input') do
  it { should exist }
  its('content') { should eq "some test input, even with funny characters like \" and '." }
end

describe file('/tmp/should-not-exist') do
  it { should_not exist }
end

describe file('/tmp/only-if-ok') do
  it { should exist }
end

describe file('/tmp/not-if-ok') do
  it { should exist }
end

describe file('/tmp/not-if-smoke') do
  it { should exist }
end

describe file('/tmp/notify-before') do
  it { should exist }
end

describe file('/tmp/notify-before-only_if_remote') do
  it { should exist }
end

describe file('/tmp/notify-before-not_if_remote') do
  it { should exist }
end
