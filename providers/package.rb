#
# Author:: Sean OMeara (<someara@opscode.com>)
# Cookbook Name:: pkgin
# Provider:: package
#
# Copyright:: 2012, Opscode, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


def initialize(*args)
  super
  @action = :install
end

def pkg_installed?(package_name)
    system("pkgin list | awk '{ split($1,a,\"-[0-9]\"); print a[1] }' | grep ^#{package_name}$")
end

def pkg_available?(package_name)
    system("pkgin avail | awk '{ split($1,a,\"-[0-9]\"); print a[1] }' | grep ^#{package_name}$")
end

action :install do
  unless pkg_installed? "#{new_resource.name}" then
    Chef::Log.info "Installing #{new_resource.name} with pkgin"
    
    if pkg_available?("#{new_resource.name}")
        system("pkgin -y install #{new_resource.name}")
      end
      new_resource.updated_by_last_action(true)
    end
end

action :remove do
  if pkg_installed? "#{new_resource.name}" then
    Chef::Log.info "Removing #{new_resource.name} with pkgin"
    system("pkgin -y remove #{new_resource.name}")
  end
  new_resource.updated_by_last_action(true)
end

