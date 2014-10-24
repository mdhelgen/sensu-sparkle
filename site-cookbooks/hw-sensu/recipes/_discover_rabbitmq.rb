#
# Cookbook Name:: hw-sensu
# Recipe:: _discover_rabbitmq
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

rabbitmq_nodes = search(:node, "chef_environment:#{node.chef_environment} AND recipes:hw-sensu\\:\\:rabbitmq")

expanded_recipes = node.run_list.expand(node.chef_environment).recipes

if expanded_recipes.include?('hw-sensu::rabbitmq')
  rabbitmq_nodes << node
  rabbitmq_nodes.uniq! { |n| n.name }
end

rabbitmq_nodes.sort!

node.run_state['hw-sensu'] ||= Mash.new
node.run_state['hw-sensu']['rabbitmq_nodes'] = rabbitmq_nodes

node.override['sensu']['rabbitmq']['host'] = rabbitmq_nodes.first['cloud']['public_ipv4']
