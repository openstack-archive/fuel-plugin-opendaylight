require 'yaml'

module Puppet::Parser::Functions
  newfunction(:odl_hiera_overrides, :type => :rvalue, :arity => 6) do |args|

    odl, neutron_config, neutron_advanced_configuration, network_scheme, mgmt_vip, standalone_mode = args

    hiera_overrides = {}
    configuration = {}

    mechanism_driver = odl['odl_v2'] ? 'opendaylight_v2' : 'opendaylight'
    # The list of drivers that can be enabled can be found here
    # https://github.com/openstack/networking-odl/blob/master/devstack/settings#L79
    # or https://github.com/openstack/networking-odl/commit/9aab23a3c3fd8aa7ade1e8edc150dd24ee3f5948
    # In Newton by default dns and port_security are enabled, but networking-odl doesn't support dns,
    # and because of that floating IPs cannot be assigned. So we disable dns here.
    extension_drivers = 'port_security'

    ml2_plugin = {
      'neutron_plugin_ml2' => {
        'ml2/mechanism_drivers' => {'value' => mechanism_driver},
        'ml2/extension_drivers' => {'value' => extension_drivers},
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
    l3_agent =  {
      'neutron_l3_agent_config' => {
        'DEFAULT/external_network_bridge' => {'value' => 'br-ex'}
      }
    }

    # When L3 forward is enabled in odl there is no neutron l3 agent
    # which normally proxy request to metadata agent. Dhcp agent can
    # takeover this task
    # Use vsctl ovsdb interface instead of native which is default
    # since Newton release. Using older interface prevents neutron
    # from switching ovs to listen in passive mode (ptcp:6640)
    # https://bugs.launchpad.net/neutron/+bug/1614766
    dhcp_agent =  {
      'neutron_dhcp_agent_config' => {
        'DEFAULT/force_metadata' => {'value' => true}
      }
    }

    neutron_ovs_config = {
      'neutron_config' => {
        'OVS/ovsdb_interface' => {'value' => 'vsctl'}
      }
    }

    unless standalone_mode
      configuration.merge! ml2_plugin
      configuration.merge! l3_agent
      configuration.merge! dhcp_agent
      configuration.merge! neutron_ovs_config
    end

    hiera_overrides['configuration'] = configuration
    hiera_overrides['configuration_options'] = { 'create' => false }

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

    return hiera_overrides.to_yaml
  end
end
