require 'knife_profitbricks_fog/base'
require 'knife_profitbricks_fog/config'
require 'knife_profitbricks_fog/data_center'
require 'knife_profitbricks_fog/ssh_commands'
require 'knife_profitbricks_fog/create_server'
require 'knife_profitbricks_fog/update_server'
require 'knife_profitbricks_fog/provision'

module KnifeProfitbricksFog
  class ProfitbricksServerCook < Chef::Knife
    include KnifeProfitbricksFog::Base
    include KnifeProfitbricksFog::Config
    include KnifeProfitbricksFog::DataCenter
    include KnifeProfitbricksFog::SshCommands
    include KnifeProfitbricksFog::CreateServer
    include KnifeProfitbricksFog::UpdateServer
    include KnifeProfitbricksFog::Provision
      
    deps do
      require 'net/ssh'
      require 'net/ssh/multi'
      
      require 'chef/mixin/command'
      require 'chef/knife'
      require 'chef/knife/solo_bootstrap'
      require 'chef/knife/solo_cook'
      require 'chef/json_compat'
      
      require 'securerandom'
      require 'timeout'
      require 'socket'
    end

    banner "knife profitbricks server cook OPTIONS"

    option :run_list,
      :short => "-r RUN_LIST",
      :long => "--run-list RUN_LIST",
      :description => "Comma separated list of roles/recipes to apply",
      :proc => lambda { |o| Chef::Config[:knife][:run_list] = o.split(/[\s,]+/) },
      :default => []

    option :profitbricks_image,
      :short => "-image NAME",
      :long => "--profitbricks-image NAME",
      :description => "Profitbricks image name",
      :proc => lambda { |o| Chef::Config[:knife][:profitbricks_image] = o }

    option :chef_node_name,
      :short => "-N NAME",
      :long => "--node-name NAME",
      :description => "The Chef node name for your new server node",
      :proc => Proc.new { |o| Chef::Config[:knife][:chef_node_name] = o }

    def run
      compute
      dc

      server
      check_server_state!
      add_server_to_known_hosts__if_new
      bootstrap_or_cook

#      reboot_server__if_new
    end

    private
      
    def server
      @server ||= (find_and_update_server || create_server)
    end
  end
end
