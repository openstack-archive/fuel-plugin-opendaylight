class opendaylight::hiera_override {
  include opendaylight
  $override_file = '/etc/hiera/plugins/opendaylight.yaml'

  # override network scheme
  $orig_network_scheme = hiera_hash('network_scheme')
  $network_scheme = odl_network_scheme($opendaylight::odl_settings['enable_bgpvpn'], $orig_network_scheme)
  $ovsdb_managers = odl_ovsdb_managers($opendaylight::odl_mgmt_ips)

  $odl_hiera_yaml = odl_hiera_overrides(
    $override_file,
    $opendaylight::odl_settings,
    hiera('neutron_config'),
    hiera('neutron_advanced_configuration'),
    $network_scheme,
    hiera('management_vip'),
    $ovsdb_managers
  )

  file { $override_file:
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    content => $odl_hiera_yaml,
  }
}
