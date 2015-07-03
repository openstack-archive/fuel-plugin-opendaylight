class opendaylight::service (
  $tomcat_port = 8282,
  $bind_address = undef
) {

  $nodes_hash = hiera('nodes', {})
  $roles = node_roles($nodes_hash, hiera('uid'))

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
                      '/opt/opendaylight/configuration/tomcat-server.xml',
                      '/opt/opendaylight/etc/jetty.xml'],
    }

    debug("Set odl rest api port to ${tomcat_port}")

    file { '/opt/opendaylight/configuration/tomcat-server.xml':
      ensure  => file,
      owner   => 'odl',
      content => template('opendaylight/tomcat-server.xml.erb')
    }

    file { '/opt/opendaylight/etc/jetty.xml':
      ensure  => file,
      owner   => 'odl',
      content => template('opendaylight/jetty.xml.erb')
    }

    exec { 'wait-until-odl-ready':
      command   => 'netstat -lpen --tcp | grep java |  grep 6633',
      path      => '/bin:/usr/bin',
      tries     => 60,
      try_sleep => 10,
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
