class opendaylight::hiera_override {
  include opendaylight
  $override_file = '/etc/hiera/plugins/opendaylight.yaml'

  # override network scheme
  $orig_network_scheme = hiera_hash('network_scheme')
  $network_scheme = odl_network_scheme($opendaylight::odl_settings['enable_bgpvpn'], $orig_network_scheme)

  odl_hiera_overrides(
    $override_file,
    $opendaylight::odl_settings,
    hiera('neutron_config'),
    hiera('neutron_advanced_configuration'),
    $network_scheme,
    hiera('management_vip')
  )

  $neutron_dirs = [ '/etc/neutron/', '/etc/neutron/plugins', '/etc/neutron/plugins/ml2' ]
  file { $neutron_dirs:
    ensure => directory,
    owner  => root,
    group  => root,
    mode   => 0644,
  }
}
