#
# Cookbook Name:: hw-graphite
# Recipe:: _carbon
#
# Copyright 2014, Heavy Water Operations, LLC.
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

include_recipe 'graphite::carbon'

graphite = data_bag('graphite')

if graphite.include?('storage_schemas')
  storage_schemas = data_bag_item('graphite', 'storage_schemas')
  storage_schemas['configs'].each do |schema|
    graphite_storage_schema schema['id'] do
      config schema['config']
    end
  end
end

if graphite.include?('carbon_caches')
  carbon_caches = data_bag_item('graphite', 'carbon_caches')
  carbon_caches['configs'].each do |cache|
    graphite_carbon_cache cache['id'] do
      config cache['config']
    end
  end

  include_recipe 'runit'
  graphite_service 'cache'
end
