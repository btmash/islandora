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

# restarting tomcat is required so that objects are created successfully
# with no Tuque un-authorized exceptions
service "tomcat" do
  action :restart
end

# use Drush to install Islandora solution pack objects
node['islandora']['solution_pack_objects'].each do |param|
  drupal_module param do
    dir node['drupal']['dir']
    action :ispiro
  end
end
