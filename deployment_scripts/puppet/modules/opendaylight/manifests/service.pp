class opendaylight::service (
  $rest_port = $opendaylight::rest_api_port,
  $bind_address = undef,
) {

  $nodes_hash = hiera('nodes', {})
  $roles = node_roles($nodes_hash, hiera('uid'))
  $management_vip = hiera('management_vip')
  $odl = hiera('opendaylight')
  $features = $odl['metadata']['odl_features']
  $enable = {}
  $enable_l3_odl = $odl['enable_l3_odl']

  if member($roles, 'opendaylight') {

    firewall {'215 odl':
      port   => [ $opendaylight::rest_api_port, 6633, 6640, 6653, 8181, 8101],
      proto  => 'tcp',
      action => 'accept',
      before => Service['opendaylight'],
    }

    service { 'opendaylight' :
      ensure  => running,
      enable  => true,
      require => File[
                      '/opt/opendaylight/etc/jetty.xml',
                      '/opt/opendaylight/etc/custom.properties',
                      '/opt/opendaylight/etc/org.apache.karaf.features.cfg'],
    }

    debug("Set odl rest api port to ${rest_port}")

    file { '/opt/opendaylight/etc/jetty.xml':
      ensure  => file,
      owner   => 'odl',
      content => template('opendaylight/jetty.xml.erb')
    }

    file { '/opt/opendaylight/etc/custom.properties':
      ensure  => file,
      owner   => 'odl',
      content => template('opendaylight/custom.properties.erb'),
    }

    $enable['default'] = $features['default']
    $enable['ovs'] = $features['ovs']
    if $odl['enable_sfc'] {
      $enable['sfc'] = $features['sfc']
    }
    if $odl['enable_gbp'] {
      $enable['gbp'] = $features['gbp']
    }

    file { '/opt/opendaylight/etc/org.apache.karaf.features.cfg':
      ensure  => file,
      owner   => 'odl',
      content => template('opendaylight/org.apache.karaf.features.cfg.erb'),
    }

    exec { 'wait-until-odl-ready':
      command   => "curl -o /dev/null --fail --silent --head -u admin:admin http://${management_vip}:${rest_port}/restconf/operational/network-topology:network-topology/topology/netvirt:1",
      path      => '/bin:/usr/bin',
      tries     => 60,
      try_sleep => 20,
      require   => Service['opendaylight'],
    }
  }

  if member($roles, 'controller') or member($roles, 'primary-controller') {
    include opendaylight::ha::haproxy
  }
}
