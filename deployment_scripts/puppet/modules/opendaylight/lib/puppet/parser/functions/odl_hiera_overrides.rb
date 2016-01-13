require 'yaml'

module Puppet::Parser::Functions
  newfunction(:odl_hiera_overrides) do |args|
    filename = args[0]
    node_roles = args[1]
    hiera_overrides = {}

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

    hiera_overrides['configuration'] = l3_agent
    # override neutron_config/quantum_settings
    neutron_config = function_hiera(['neutron_config'])
    neutron_config['L2']['mechanism_drivers'] = 'opendaylight'
    neutron_config['L2']['phys_nets']['physnet1']['bridge'] = 'br-ex'
    hiera_overrides['neutron_config'] = neutron_config
    hiera_overrides['quantum_settings'] = neutron_config

    # override neutron_advanced_configuration
    neutron_advanced_configuration = function_hiera(['neutron_advanced_configuration'])
    neutron_advanced_configuration['neutron_dvr'] = false
    neutron_advanced_configuration['neutron_l2_pop'] = false
    neutron_advanced_configuration['l2_agent_ha'] = false
    hiera_overrides['neutron_advanced_configuration'] = neutron_advanced_configuration

    # override network scheme
    network_scheme = function_odl_network_scheme( [node_roles] )

    hiera_overrides['network_scheme'] = network_scheme
    # write to hiera override yaml file
    File.open(filename, 'w') { |file| file.write(hiera_overrides.to_yaml) }
  end
end
