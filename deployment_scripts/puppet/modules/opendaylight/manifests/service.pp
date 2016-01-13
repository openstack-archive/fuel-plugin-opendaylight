class opendaylight::service {
  $nodes_hash = hiera('nodes', {})
  $roles = node_roles($nodes_hash, hiera('uid'))
  $management_vip = hiera('management_vip')
  $odl = hiera('opendaylight')
  $rest_port = $odl['rest_api_port']

  include opendaylight::ha::haproxy

  if member($roles, 'primary-controller') {
    exec { 'wait-until-odl-ready':
      command   => "curl -o /dev/null --fail --silent --head -u admin:admin http://${management_vip}:${rest_port}/restconf/operational/network-topology:network-topology/topology/netvirt:1",
      path      => '/bin:/usr/bin',
      tries     => 60,
      try_sleep => 20,
      require   => Class['opendaylight::ha::haproxy'],
    }
  }
}
