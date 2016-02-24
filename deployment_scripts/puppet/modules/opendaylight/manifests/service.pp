class opendaylight::service {
  $nodes_hash = hiera('nodes', {})
  $roles = node_roles($nodes_hash, hiera('uid'))
  $management_vip = hiera('management_vip')
  $odl = hiera('opendaylight')
  $rest_port = $odl['rest_api_port']

  include opendaylight::ha::haproxy

  if odl['enable_bgpvpn'] {
    $odl_up_testing_site = "ovsdb:1"
  } else {
    $odl_up_testing_site = "netvirt:1"
  }
  if member($roles, 'primary-controller') {
    exec { 'wait-until-odl-ready':
      command   => "curl -o /dev/null --fail --silent --head -u admin:admin http://${management_vip}:${rest_port}/restconf/operational/network-topology:network-topology/topology/${odl_up_testing_site}",
      path      => '/bin:/usr/bin',
      tries     => 60,
      try_sleep => 20,
      require   => Class['opendaylight::ha::haproxy'],
    }
  }
}
