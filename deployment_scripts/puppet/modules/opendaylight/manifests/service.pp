class opendaylight::service {
  include opendaylight
  include opendaylight::ha::haproxy
  $management_vip = hiera('management_vip')
  $odl = hiera('opendaylight')
  $rest_port = $odl['rest_api_port']

  if roles_include(['primary-controller']) {
    exec { 'wait-until-odl-ready':
      command   => "curl -o /dev/null --fail --silent --head -u admin:admin http://${management_vip}:${rest_port}/restconf/operational/network-topology:network-topology/topology/netvirt:1",
      path      => '/bin:/usr/bin',
      tries     => 60,
      try_sleep => 20,
      require   => Class['opendaylight::ha::haproxy'],
    }
  }
}
