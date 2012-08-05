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


require 'chef/provider/package'
require 'chef/mixin/command'
require 'chef/resource/package'
require 'chef/mixin/get_source_from_package'

class Chef
  class Provider
    class Package
      class PkginPackage < Chef::Provider::Package
        
        include Chef::Mixin::ShellOut

        installed = false
        depends = false

        # def define_resource_requirements
        #   super
        #
        #   requirements.assert(:all_actions) do |a|
        #     a.assertion { ! @candidate_version.nil? }
        #     a.failure_message Chef::Exceptions::Package, "Package #{@new_resource.package_name} not found"
        #     a.whyrun "Assuming package #{@new_resource.package_name} would have been made available."
        #   end
        # end
        
        def load_current_resource
          @current_resource = Chef::Resource::Package.new(@new_resource.name)
          @current_resource.package_name(@new_resource.name)
          check_package_state(@new_resource.package_name)
          @current_resource
        end
        
        def check_package_state(package)
          Chef::Log.info("Checking package status for #{package}")

          # see whats installed
          shell_out("pkg_info #{package}").stdout.each_line do | line |
            puts "#{line}"
            case line
            when /Information for (.*)/
              installed = true
              package_info = $1.split(/(-[0-9])/)
              package_name = package_info[0]
              package_version = (package_info[1]+package_info[2]).chop.reverse.chop.reverse

              if installed
                @current_resource.version(package_version)
              else
                @current_resource.version(nil)
              end
             
              Chef::Log.info("Installed package name: #{package_name}")
              Chef::Log.info("Installed package version: #{package_version}")
            end
          end
          
          # see whats available - set candidate_version
          shell_out("pkgin avail apache | grep ^apache-[0-9] | awk '{ print $1 }'").stdout.each_line do | line |
            package_info = line.split(/(-[0-9])/)
            package_name = package_info[0]
            package_version = (package_info[1]+package_info[2]).reverse.chop.reverse
            @candidate_version = package_version
          end
                
          def install_package(name, version)
            full_package_name = "#{name}-#{version}"
            run_command_with_systems_locale(
              :command => "pkgin -y install #{full_package_name}")
          end

          def upgrade_package(name, version)
            install_package(name, version)
          end
          
          def remove_package(name, version)
            full_package_name = "#{name}-#{version}"
            run_command_with_systems_locale(
              :command => "pkgin -y remove #{full_package_name}")
          end
          
        end
      end
    end
  end
end
