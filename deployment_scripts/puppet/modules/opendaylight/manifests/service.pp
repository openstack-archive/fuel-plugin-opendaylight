class opendaylight::service {
  include opendaylight::ha::haproxy

  $management_vip = hiera('management_vip')
  $odl = $opendaylight::odl_settings
  $user = $odl['metadata']['default_credentials']['user']
  $password = $odl['metadata']['default_credentials']['password']

  $rest_port = $opendaylight::rest_api_port

  if roles_include(['primary-controller']) {
    exec { 'wait-until-odl-ready':
      command   => join([
        "curl -o /dev/null --fail --silent --head -u ${user}:${password}",
        "http://${management_vip}:${rest_port}/restconf/operational/network-topology:network-topology/topology/netvirt:1"
      ], ' '),
      path      => '/bin:/usr/bin',
      tries     => 60,
      try_sleep => 20,
      require   => Class['opendaylight::ha::haproxy'],
    }
  }
}
