class opendaylight::service {
  include opendaylight
  include opendaylight::ha::haproxy
  $management_vip = hiera('management_vip')
  $odl = hiera('opendaylight')
  $user = $odl['metadata']['default_credentials']['user']
  $password = $odl['metadata']['default_credentials']['password']

  $rest_port = $odl['rest_api_port']

  if $odl['enable_bgpvpn'] {
    $odl_up_testing_site = "ovsdb:1"
  } else {
    $odl_up_testing_site = "netvirt:1"
  }
  if roles_include(['primary-controller']) {
    exec { 'wait-until-odl-ready':
      command   => "curl -o /dev/null --fail --silent --head -u ${user}:${password} http://${management_vip}:${rest_port}/restconf/operational/network-topology:network-topology/topology/${odl_up_testing_site}",
      path      => '/bin:/usr/bin',
      tries     => 60,
      try_sleep => 20,
      require   => Class['opendaylight::ha::haproxy'],
    }
  }
}
