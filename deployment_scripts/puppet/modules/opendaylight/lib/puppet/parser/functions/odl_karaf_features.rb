module Puppet::Parser::Functions
  newfunction(:odl_karaf_features, :arity => 1, :type => :rvalue) do |args|
    odl_settings = args[0]
    features_set = odl_settings['metadata']['odl_features']

    enabled_features = []
    enabled_features << features_set['default']
    enabled_features << features_set['odl-default']
    enabled_features << features_set['ovs']
    enabled_features << features_set['sfc'] if odl_settings['enable_sfc']
    enabled_features << features_set[odl_settings['sfc_class']] if odl_settings['enable_sfc']

    enabled_features.join(',')
  end
end
