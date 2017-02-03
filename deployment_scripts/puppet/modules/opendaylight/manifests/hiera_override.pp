class opendaylight::hiera_override {
  include opendaylight
  $override_file = '/etc/hiera/plugins/opendaylight.yaml'

  # override network scheme
  $orig_network_scheme = hiera_hash('network_scheme')
  $network_scheme = odl_network_scheme($opendaylight::odl_settings['enable_bgpvpn'], $orig_network_scheme)
  $ovsdb_managers = odl_ovsdb_managers($opendaylight::odl_mgmt_ips)
  $standalone_mode = roles_include(['opendaylight']) and size(hiera('roles')) == 1

  $odl_hiera_yaml = odl_hiera_overrides(
    $opendaylight::odl_settings,
    hiera('neutron_config'),
    hiera('neutron_advanced_configuration'),
    $network_scheme,
    hiera('management_vip'),
    $standalone_mode
  )

  file { $override_file:
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    content => $odl_hiera_yaml,
  }
}
