module Puppet::Parser::Functions
  newfunction(:odl_karaf_features, :type => :rvalue) do |args|
    odl_settings = function_hiera(['opendaylight'])
    network_metadata = function_hiera(['network_metadata'])
    odl_nodes = function_get_nodes_hash_by_roles([network_metadata, ['opendaylight'] ])
    features_set = odl_settings['metadata']['odl_features']

    enabled_features = []
    enabled_features << features_set['default']
    enabled_features << features_set['odl-default']
    enabled_features << features_set['ovs'] if not odl_settings['enable_bgpvpn']
    enabled_features << features_set['sfc'] if odl_settings['enable_sfc']
    enabled_features << features_set[odl_settings['sfc_class']] if odl_settings['enable_sfc']
    enabled_features << features_set['vpn'] if odl_settings['enable_bgpvpn']
    enabled_features << features_set['cluster'] if odl_nodes.size > 1

    enabled_features.join(',')
  end
end
