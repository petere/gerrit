#
# Cookbook Name:: gerrit
# Recipe:: default
#
# Copyright 2011, Myplanet Digital
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

user node['gerrit']['user'] do
  uid node['gerrit']['uid']
  gid node['gerrit']['group']
  home "/home/#{node['gerrit']['user']}"
  comment "Gerrit system user"
  action :manage
end

remote_file "#{Chef::Config[:file_cache_path]}/gerrit.war" do
  owner node['gerrit']['user']
  source "http://gerrit.googlecode.com/files/gerrit-#{node['gerrit']['version']}.war"
  checksum node['gerrit']['checksum'][node['gerrit']['version']]
end

require_recipe "build-essential"
require_recipe "mysql"
require_recipe "mysql::server"
require_recipe "database"

mysql_connection_info = {
    :host =>  "localhost",
    :username => "root",
    :password => node['mysql']['server_root_password']
  }

mysql_database "reviewdb" do
  connection mysql_connection_info
  action :create
end

mysql_database "changing the charset of reviewdb" do
  connection mysql_connection_info
  action :query
  sql "ALTER DATABASE reviewdb charset=latin1"
end

mysql_database_user "gerrit2" do
  connection mysql_connection_info
  password node['mysql']['server_root_password']
  action :create
end

mysql_database_user "gerrit2" do
  connection mysql_connection_info
  database_name "reviewdb"
  privileges [
    :all
  ]
  action :grant
end

mysql_database "flushing mysql privileges" do
  connection mysql_connection_info
  action :query
  sql "FLUSH PRIVILEGES"
end

require_recipe "java"
require_recipe "git"

bash "Initializing Gerrit site" do
  user node['gerrit']['user']
  group node['gerrit']['group']
  cwd Chef::Config[:file_cache_path]
  code <<-EOH
  java -jar gerrit.war init -d /home/#{node['gerrit']['user']}/review_site
  EOH
end

#template "" do
#  source
#end

bash "Starting gerrit daemon" do
  user node['gerrit']['user']
  group node['gerrit']['group']
  code <<-EOH
  /home/#{node['gerrit']['user']}/review_site/bin/gerrit.sh start
  EOH
end

link "/etc/init.d/gerrit.sh" do
  to "/home/#{node['gerrit']['user']}/review_site/bin/gerrit.sh"
end

link "/etc/rc3.d/S90gerrit" do
  to "../init.d/gerrit.sh"
end

#service "gerrit" do
#end
