#
# Cookbook Name:: hw-sensu
# Recipe:: _discover_redis
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

expanded_recipes = node.run_list.expand(node.chef_environment).recipes

redis_node = case
when expanded_recipes.include?('hw-sensu::redis')
  node
else
  redis_nodes = search(:node, "chef_environment:#{node.chef_environment} AND recipes:hw-sensu\\:\\:redis")
  redis_nodes.sort { |a, b| b['ohai_time'] <=> a['ohai_time'] }.first
end

node.run_state['hw-sensu'] ||= Mash.new
node.run_state['hw-sensu']['redis_node'] = redis_node

node.override['sensu']['redis']['host'] = redis_node['cloud']['local_ipv4']
