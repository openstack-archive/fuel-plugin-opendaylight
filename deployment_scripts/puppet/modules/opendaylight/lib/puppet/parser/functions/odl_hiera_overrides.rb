require 'yaml'

module Puppet::Parser::Functions
  newfunction(:odl_hiera_overrides) do |args|
    filename = args[0]
    hiera_overrides = {}

    # override neutron_config/quantum_settings
    neutron_config = function_hiera(['neutron_config'])
    neutron_config['L2']['mechanism_drivers'] = 'opendaylight'
    hiera_overrides['neutron_config'] = neutron_config
    hiera_overrides['quantum_settings'] = neutron_config

    # override neutron_advanced_configuration
    neutron_advanced_configuration = function_hiera(['neutron_advanced_configuration'])
    neutron_advanced_configuration['neutron_dvr'] = false
    neutron_advanced_configuration['neutron_l2_pop'] = false
    neutron_advanced_configuration['l2_agent_ha'] = false
    hiera_overrides['neutron_advanced_configuration'] = neutron_advanced_configuration

    # write to hiera override yaml file
    File.open(filename, 'w') { |file| file.write(hiera_overrides.to_yaml) }
  end
end
