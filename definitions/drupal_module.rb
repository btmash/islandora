#
# Author:: Marius Ducea (marius@promethost.com)
# Cookbook Name:: drupal
# Definition:: drupal_module
#
# Copyright 2010, Promet Solutions
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
#

define :drupal_module, :action => :install, :dir => nil, :version => nil do
  case params[:action]
  when :install
    if params[:dir] == nil then
      log("drupal_module_install requires a working drupal dir") { level :fatal }
      raise "drupal_module_install requires a working drupal dir"
    end
    execute "drush_dl_module #{params[:name]}" do
      cwd params[:dir]
      user node['drupal']['system']['user']
      command "#{node['drupal']['drush']['dir']}/drush -y dl #{params[:name]} #{node['drupal']['drush']['options']}"
      not_if "#{node['drupal']['drush']['dir']}/drush -r #{params[:dir]} pm-list |grep '(#{params[:name]})' |grep '#{params[:version]}'"
      retries 3
    end
    execute "drush_en_module #{params[:name]}" do
      cwd params[:dir]
      user node['drupal']['system']['user']
      command "#{node['drupal']['drush']['dir']}/drush -y en #{params[:name]} #{node['drupal']['drush']['options']}"
      not_if "#{node['drupal']['drush']['dir']}/drush -r #{params[:dir]} pm-list |grep '(#{params[:name]})' |grep -i 'enabled'"
      retries 3
    end
  when :php_eval
    execute "drush_php_eval #{params[:name]}" do
      cwd params[:dir]
      user node['drupal']['system']['user']
      # NB: params[:variable] and params[:value] ARE REQUIRED
      if params[:variable] == nil or params[:value] == nil then
        log("drupal_module_drush_php_eval requires arguments for variable and value") { level :fatal }
        raise "drupal_module_drush_php_eval requires arguments for variable and value"
      end
      command "#{node['drupal']['drush']['dir']}/drush -y php-eval \"variable_set('#{params[:variable]}', '#{params[:value]}')\""
    end
  when :php_eval_noquote
    execute "drush_php_eval #{params[:name]}" do
      cwd params[:dir]
      user node['drupal']['system']['user']
      # NB: params[:variable] and params[:value] ARE REQUIRED
      if params[:variable] == nil or params[:value] == nil then
        log("drupal_module_drush_php_eval_noquote requires arguments for variable and value") { level :fatal }
        raise "drupal_module_drush_php_eval_noquote requires arguments for variable and value"
      end
      command "#{node['drupal']['drush']['dir']}/drush -y php-eval \"variable_set('#{params[:variable]}', #{params[:value]})\""
    end
  when :enable
    execute "drush_en_module #{params[:name]}" do
      cwd params[:dir]
      user node['drupal']['system']['user']
      command "#{node['drupal']['drush']['dir']}/drush -y en #{params[:name]} #{node['drupal']['drush']['options']}"
      not_if "#{node['drupal']['drush']['dir']}/drush -r #{params[:dir]} pm-list |grep '(#{params[:name]})' |grep -i 'enabled'"
      retries 3
    end
  when :ispiro
    execute "drush_islandora_solution_pack_install_required_objects #{params[:name]}" do
      cwd params[:dir]
      user node['drupal']['system']['user']
      command "#{node['drupal']['drush']['dir']}/drush -u 1 ispiro --module=#{params[:name]}"  
    end
  when :ispicm
    execute "drush_islandora_solution_pack_install_content_models #{params[:name]}" do
      cwd params[:dir]
      user node['drupal']['system']['user']
      command "#{node['drupal']['drush']['dir']}/drush -u 1 ispicm --module=#{params[:name]}"  
    end  
  else
    log "drupal_source action #{params[:name]} is unrecognized."
  end
end