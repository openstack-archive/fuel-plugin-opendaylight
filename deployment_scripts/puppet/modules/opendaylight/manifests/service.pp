class opendaylight::service (
  $rest_port = 8282,
  $bind_address = undef
) {

  $nodes_hash = hiera('nodes', {})
  $roles = node_roles($nodes_hash, hiera('uid'))
  $management_vip = hiera('management_vip')
  $odl = hiera("opendaylight")
  $features = $odl['metadata']['odl_features']
  $enable = {}

  if member($roles, 'primary-controller') {

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
    $enable['ovsdb'] = $features['ovsdb']

    if $odl['enable_sfc'] {
      $enable['config'] = $features['config']
      $enable['netconf'] = $features['netconf']
      $enable['oflp'] = $features['oflp']
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
      tries     => 50,
      try_sleep => 20,
      require   => Service['opendaylight'],
    }
  }

  if member($roles, 'controller') or member($roles, 'primary-controller') {
    include opendaylight::ha::haproxy
  }

  if $opendaylight::odl_settings['use_vxlan'] {
    firewall {'216 vxlan':
      port   => [4789],
      proto  => 'udp',
      action => 'accept',
    }
  }
}
