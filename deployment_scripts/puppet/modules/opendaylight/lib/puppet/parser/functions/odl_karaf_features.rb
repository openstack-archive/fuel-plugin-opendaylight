module Puppet::Parser::Functions
  newfunction(:odl_karaf_features, :arity => 1, :type => :rvalue) do |args|
    odl_settings = args[0]
    features_set = odl_settings['metadata']['odl_features']

    enabled_features = []
    enabled_features << features_set['default']
    enabled_features << features_set['odl-default']
    enabled_features << features_set['ovs'] if not odl_settings['enable_bgpvpn']
    enabled_features << features_set['sfc'] if odl_settings['enable_sfc'] and (odl_settings['package_name'] == 'opendaylight')
    enabled_features << features_set['boron-sfc'] if odl_settings['enable_sfc'] and (odl_settings['package_name'] == 'opendaylight-boron')
    enabled_features << features_set[odl_settings['sfc_class']] if odl_settings['enable_sfc']
    enabled_features << features_set['vpn'] if odl_settings['enable_bgpvpn']

    enabled_features.join(',')
  end
end
