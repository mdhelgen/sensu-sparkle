#
# Cookbook Name:: hw-sensu
# Recipe:: enterprise
#
# Copyright 2014, Heavy Water Operations, LLC
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#

include_recipe 'hw-sensu::_base'
include_recipe 'hw-sensu::_discover_redis'
include_recipe 'hw-sensu::_handlers'
include_recipe 'hw-sensu::_checks'

platform_family = node.platform_family
platform_version = node.platform_version.to_i

enterprise = Sensu::Helpers.data_bag_item('enterprise')
credentials = enterprise['repository']['credentials']

repository_url = "http://#{credentials['user']}:#{credentials['password']}@enterprise.sensuapp.com"

case platform_family
when 'debian'
  include_recipe 'apt'

  apt_repository 'sensu-enterprise' do
    uri File.join(repository_url, 'apt')
    key File.join(repository_url, 'apt', 'pubkey.gpg')
    distribution 'sensu-enterprise'
    components ['unstable']
    action :add
  end
else
  rhel_version_equivalent = case platform_family
  when 'rhel'
    platform?('amazon') ? 6 : platform_version
  else
    raise "Unsupported Linux platform family #{platform_family}"
  end

  repo = yum_repository 'sensu-enterprise' do
    description 'sensu enterprise'
    url File.join(repository_url, 'yum-unstable', 'el', rhel_version_equivalent, '$basearch')
    action :add
  end
  repo.gpgcheck(false) if repo.respond_to?(:gpgcheck)
end

package 'sensu-enterprise' do
  action :upgrade
end

service 'sensu-enterprise' do
  subscribes :restart, resources("package[sensu-enterprise]"), :immediately
  subscribes :reload, resources("ruby_block[sensu_service_trigger]"), :delayed
  supports :status => true, :start => true, :stop => true, :restart => true, :reload => true
  action [:enable, :start]
end
