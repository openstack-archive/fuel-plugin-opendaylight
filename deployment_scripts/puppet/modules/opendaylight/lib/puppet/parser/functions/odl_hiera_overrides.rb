require 'yaml'

module Puppet::Parser::Functions
  newfunction(:odl_hiera_overrides, :arity => 6) do |args|

    filename, odl, neutron_config, neutron_advanced_configuration, network_scheme, mgmt_vip = args

    hiera_overrides = {}
    configuration = {}

    mechanism_driver = odl['odl_v2'] ? 'opendaylight_v2' : 'opendaylight'

    ml2_plugin = {
      'neutron_plugin_ml2' => {
        'ml2/mechanism_drivers' => {'value' => mechanism_driver},
        'ml2_odl/password' => {'value' => 'admin'},
        'ml2_odl/username' => {'value' => 'admin'},
        'ml2_odl/url' => {'value' => "http://#{mgmt_vip}:#{odl['rest_api_port']}/controller/nb/v2/neutron"}
      }
    }

    # When L3 forward is disabled in ODL set external_network_bridge option
    # to use neutron L3 agent to create qg port on selected bridge
    # Without this floating IPs doesn't work.
    # This option will be no longer used in Mitaka release.
    # Must be changed before that!
    l3_agent = {
      'neutron_l3_agent_config' => {
        'DEFAULT/external_network_bridge' => {'value' => 'br-ex'}
      }
    }

    # When L3 forward is enabled in odl there is no neutron l3 agent
    # which normally proxy request to metadata agent. Dhcp agent can
    # takeover this task
    dhcp_agent =  {
      'neutron_dhcp_agent_config' => {
        'DEFAULT/force_metadata' => {'value' => true}
      }
    }

    configuration.merge! ml2_plugin
    configuration.merge! l3_agent
    configuration.merge! dhcp_agent if odl['enable_l3_odl']
    hiera_overrides['configuration'] = configuration

    # override neutron_config/quantum_settings
    neutron_config['L2']['mechanism_drivers'] = 'opendaylight'
    neutron_config['L2']['phys_nets']['physnet1']['bridge'] = odl['enable_bgpvpn'] ? 'br-ex' : 'br-int'

    hiera_overrides['neutron_config'] = neutron_config
    hiera_overrides['quantum_settings'] = neutron_config

    # override neutron_advanced_configuration
    neutron_advanced_configuration['neutron_dvr'] = false
    neutron_advanced_configuration['neutron_l2_pop'] = false
    neutron_advanced_configuration['l2_agent_ha'] = false
    hiera_overrides['neutron_advanced_configuration'] = neutron_advanced_configuration

    hiera_overrides['network_scheme'] = network_scheme
    # write to hiera override yaml file
    File.open(filename, 'w') { |file| file.write(hiera_overrides.to_yaml) }
  end
end
