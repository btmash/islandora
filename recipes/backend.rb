#
# Cookbook Name:: islandora
# Recipe:: backend
#
# Copyright 2014, University of Toronto Libraries, Ryerson University Library and Archives
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

# Download Drupal filter
# TODO: rework this to build the filter against the installed version of fedora
remote_file "#{node['tomcat']['webapp_dir']}/fedora/WEB-INF/lib/fcrepo-drupalauthfilter.jar" do
  source "https://raw.github.com/ryersonlibrary/islandora/master/jars/fcrepo-drupalauthfilter-3.7.0.jar"
  checksum node['drupal_filter']['sha256']
  owner node['tomcat']['user']
  group node['tomcat']['group']
  mode 0644
end

# set Drupal auth type in jaas.conf (assumes FESL)
template "#{node['fedora']['installpath']}/server/config/jaas.conf" do
  source "jaas.conf.erb"

  owner node['tomcat']['user']
  group node['tomcat']['group']
end

# template filter-drupal.xml
template "#{node['fedora']['installpath']}/server/config/filter-drupal.xml" do
  source "filter-drupal.xml.erb"

  owner node['tomcat']['user']
  group node['tomcat']['group']

  # Force Tomcat to reload
  notifies :start, "service[tomcat]"
end

include_recipe 'git'

# Checkout solr config from YorkU repo (because it's the most recent / Solr 4.2.O)
git "#{node['solr']['installpath']}/#{node['solr']['core_name']}/conf/basic-solr-config" do
  repository "git://github.com/yorkulibraries/basic-solr-config.git"
  action :checkout
  user node['tomcat']['user']
  group node['tomcat']['group']
end

# Remove default schema/config files
file "#{node['solr']['installpath']}/#{node['solr']['core_name']}/conf/schema.xml" do
  action :delete
end

file "#{node['solr']['installpath']}/#{node['solr']['core_name']}/conf/solrconfig.xml" do
  action :delete
end

# Symlink new schema file from YorkU repo
link "#{node['solr']['installpath']}/#{node['solr']['core_name']}/conf/schema.xml" do
  to "#{node['solr']['installpath']}/#{node['solr']['core_name']}/conf/basic-solr-config/conf/schema.xml"
  owner node['tomcat']['user']
  group node['tomcat']['group']
  
  # Force Tomcat to reload when we're done
  notifies :start, "service[tomcat]"
end

# Generate Solr config from template
template "#{node['solr']['installpath']}/#{node['solr']['core_name']}/conf/solrconfig.xml" do
  source "solrconfig.xml.erb"

  owner node['tomcat']['user']
  group node['tomcat']['group']
end

# TODO: modify + symlink / template foxmlToSolr.xslt from repo to transforms dir
# Needs to have paths updated

# delete foxmlToSolr.xslt file
file "#{node['solr']['installpath']}/#{node['solr']['core_name']}/conf/basic-solr-config/foxmlToSolr.xslt" do
  action :delete
end

# create new foxmlToSolr.xslt with correct paths
template "#{node['solr']['installpath']}/#{node['solr']['core_name']}/conf/basic-solr-config/foxmlToSolr.xslt" do
  source "foxmlToSolr.xslt.erb"

  owner node['tomcat']['user']
  group node['tomcat']['group']
end

# delete slurp_all_MODS_to_solr.xslt file
file "#{node['solr']['installpath']}/#{node['solr']['core_name']}/conf/basic-solr-config/islandora_transforms/slurp_all_MODS_to_solr.xslt" do
  action :delete
end

# create new slurp_all_MODS_to_solr.xslt with correct paths
template "#{node['solr']['installpath']}/#{node['solr']['core_name']}/conf/basic-solr-config/islandora_transforms/slurp_all_MODS_to_solr.xslt" do
  source "slurp_all_MODS_to_solr.xslt.erb"

  owner node['tomcat']['user']
  group node['tomcat']['group']
end

# Symlink foxmlToSolr into gsearch
link "#{node['tomcat']['webapp_dir']}/fedoragsearch/WEB-INF/classes/fgsconfigFinal/index/FgsIndex/foxmlToSolr.xslt" do
  to "#{node['solr']['installpath']}/#{node['solr']['core_name']}/conf/basic-solr-config/foxmlToSolr.xslt"
  owner node['tomcat']['user']
  group node['tomcat']['group']
  
  # Force Tomcat to reload when we're done
  notifies :start, "service[tomcat]"
end

# Symlink XSLT files into gsearch
link "#{node['tomcat']['webapp_dir']}/fedoragsearch/WEB-INF/classes/fgsconfigFinal/index/FgsIndex/islandora_transforms" do
  to "#{node['solr']['installpath']}/#{node['solr']['core_name']}/conf/basic-solr-config/islandora_transforms"
  owner node['tomcat']['user']
  group node['tomcat']['group']
  
  # Force Tomcat to reload when we're done
  notifies :start, "service[tomcat]"
end

# Checkout islandora module to get XACML policies
# NB: this will clone the WHOLE repo, even though we only want one folder
git "#{node['fedora']['installpath']}/data/islandora" do
  repository "git://github.com/Islandora/islandora.git"
  action :checkout

  branch node['islandora']['version']

  user node['tomcat']['user']
  group node['tomcat']['group']
end

link "#{node['fedora']['installpath']}/data/fedora-xacml-policies/repository-policies/islandora" do
  to "#{node['fedora']['installpath']}/data/islandora/policies"
  owner node['tomcat']['user']
  group node['tomcat']['group']
  
  # Force Tomcat to reload when we're done
  notifies :start, "service[tomcat]"
end

# get Solr ISO-639 filter
directory "#{node['solr']['installpath']}/contrib/iso639/lib" do
  recursive true
end

remote_file "#{node['solr']['installpath']}/contrib/iso639/lib/solr-iso639-filter-4.2.0-r20131208.jar" do
  source "https://raw.github.com/ryersonlibrary/islandora/master/jars/solr-iso639-filter-4.2.0-r20131208.jar"
  checksum node['solr-iso639-filter']['sha256']
  owner node['tomcat']['user']
  group node['tomcat']['group']
  mode 0644

  # Force Tomcat to reload when we're done
  notifies :start, "service[tomcat]"
end

# get GSearch extensions jars
remote_file "#{node['tomcat']['webapp_dir']}/fedoragsearch/WEB-INF/lib/gsearch_extensions-0.1.0.jar" do
  source "https://raw.github.com/ryersonlibrary/islandora/master/jars/gsearch_extensions-0.1.0.jar"
  checksum node['gsearch_extensions']['sha256']
  owner node['tomcat']['user']
  group node['tomcat']['group']
  mode 0644

  # Force Tomcat to reload when we're done
  notifies :start, "service[tomcat]"
end

remote_file "#{node['tomcat']['webapp_dir']}/fedoragsearch/WEB-INF/lib/gsearch_extensions-0.1.0-jar-with-dependencies.jar" do
  source "https://raw.github.com/ryersonlibrary/islandora/master/jars/gsearch_extensions-0.1.0-jar-with-dependencies.jar"
  checksum node['gsearch_extensions-dependencies']['sha256']
  owner node['tomcat']['user']
  group node['tomcat']['group']
  mode 0644

  # Force Tomcat to reload when we're done
  notifies :start, "service[tomcat]"
end
