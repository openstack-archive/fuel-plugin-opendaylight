require 'yaml'

module Puppet::Parser::Functions
  newfunction(:odl_hiera_overrides) do |args|
    filename = args[0]
    node_roles = args[1]
    odl = function_hiera(['opendaylight'])
    management_vip = function_hiera(['management_vip'])
    hiera_overrides = {}
    configuration = {}

    if odl['odl_v2']
      mechanism_driver = 'opendaylight_v2'
    else
      mechanism_driver = 'opendaylight'
    end

    ml2_plugin = {'neutron_plugin_ml2' =>
                   {'ml2/mechanism_drivers' => {'value' => mechanism_driver},
                   'ml2_odl/password' => {'value' => 'admin'},
                   'ml2_odl/username' => {'value' => 'admin'},
                   'ml2_odl/url' => {'value' => "http://#{management_vip}:#{odl['rest_api_port']}/controller/nb/v2/neutron"}
                   }
                 }

    # When L3 forward is disabled in ODL set external_network_bridge option
    # to use neutron L3 agent to create qg port on selected bridge
    # Without this floating IPs doesn't work.
    # This option will be no longer used in Mitaka release.
    # Must be changed before that!
    l3_agent =  {'neutron_l3_agent_config' =>
                  {'DEFAULT/external_network_bridge' =>
                    {'value' => 'br-ex'}
                  }
                }

    # When L3 forward is enabled in odl there is no neutron l3 agent
    # which normally proxy request to metadata agent. Dhcp agent can
    # takeover this task
    dhcp_agent =  {'neutron_dhcp_agent_config' =>
                    {'DEFAULT/force_metadata' =>
                      {'value' => true}
                    }
                  }

    configuration.merge! ml2_plugin
    configuration.merge! l3_agent
    configuration.merge! dhcp_agent if odl['enable_l3_odl']
    hiera_overrides['configuration'] = configuration

    # override neutron_config/quantum_settings
    neutron_config = function_hiera(['neutron_config'])
    neutron_config['L2']['mechanism_drivers'] = 'opendaylight'
    if odl['enable_bgpvpn']
      neutron_config['L2']['phys_nets']['physnet1']['bridge'] = 'br-ex'
    else
      neutron_config['L2']['phys_nets']['physnet1']['bridge'] = 'br-int'
    end
    hiera_overrides['neutron_config'] = neutron_config
    hiera_overrides['quantum_settings'] = neutron_config

    # override neutron_advanced_configuration
    neutron_advanced_configuration = function_hiera(['neutron_advanced_configuration'])
    neutron_advanced_configuration['neutron_dvr'] = false
    neutron_advanced_configuration['neutron_l2_pop'] = false
    neutron_advanced_configuration['l2_agent_ha'] = false
    hiera_overrides['neutron_advanced_configuration'] = neutron_advanced_configuration

    # override network scheme
    orig_network_scheme = function_hiera_hash(['network_scheme'])
    network_scheme = function_odl_network_scheme([odl['enable_bgpvpn'], orig_network_scheme])

    hiera_overrides['network_scheme'] = network_scheme
    # write to hiera override yaml file
    File.open(filename, 'w') { |file| file.write(hiera_overrides.to_yaml) }
  end
end
