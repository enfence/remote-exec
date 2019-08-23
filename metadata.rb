name 'remote-exec'
maintainer 'eNFence GmbH'
maintainer_email 'andrey.klyachkin@enfence.com'
license 'Apache-2.0'
description 'remote_execute resource for Chef'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version '0.2.0'
issues_url 'https://github.com/enfence/remote-exec/issues' if respond_to?(:issues_url)
source_url 'https://github.com/enfence/remote-exec' if respond_to?(:source_url)
chef_version '~> 12.0'
chef_version '~> 13.0'
chef_version '~> 14.0'
supports 'ubuntu', '= 16.04'
supports 'ubuntu', '= 18.04'
supports 'centos', '~> 7'
