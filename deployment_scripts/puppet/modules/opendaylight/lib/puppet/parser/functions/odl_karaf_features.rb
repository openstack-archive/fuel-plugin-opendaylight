module Puppet::Parser::Functions
  newfunction(:odl_karaf_features, :type => :rvalue) do |args|
    odl_settings = function_hiera(['opendaylight'])
    bgpvpn = function_hiera(['bgpvpn', false])
    features_set = odl_settings['metadata']['odl_features']

    enabled_features = []
    enabled_features << features_set['default']
    enabled_features << features_set['ovs']
    enabled_features << features_set['sfc'] if odl_settings['enable_sfc']
    enabled_features << features_set['gbp'] if odl_settings['enable_gbp']
    enabled_features << features_set['vpn'] if bgpvpn

    enabled_features.join(',')
  end
end
