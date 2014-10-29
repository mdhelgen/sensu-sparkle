#
# Cookbook Name:: hw-graphite
# Recipe:: _web
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

include_recipe 'graphite::web'

base_dir = node['graphite']['base_dir']
storage_dir = node['graphite']['storage_dir']

graphite_web_config "#{base_dir}/webapp/graphite/local_settings.py" do
  config({
    'secret_key' => 'super_secret',
    'time_zone' => 'America/Chicago',
    'conf_dir' => File.join(base_dir,'conf'),
    'storage_dir' => storage_dir,
    'databases' => {
      'default' => {
        # keys need to be upcase here
        'NAME' => File.join(storage_dir, 'graphite.db'),
        'ENGINE' => 'django.db.backends.sqlite3',
        'USER' => nil,
        'PASSWORD' => nil,
        'HOST' => nil,
        'PORT' => nil
      }
    }
  })
end

execute 'python manage.py syncdb --noinput' do
  user node['graphite']['user']
  group node['graphite']['group']
  cwd File.join(base_dir, 'webapp', 'graphite')
  creates File.join(storage_dir, 'graphite.db')
end

include_recipe 'graphite::uwsgi'
