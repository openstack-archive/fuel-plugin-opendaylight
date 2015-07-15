class opendaylight::service (
  $tomcat_port = 8282,
  $bind_address = undef
) {

  $karaf_default_features = ['config', 'standard', 'region', 'package', 'kar', 'ssh', 'management']
  $karaf_odl_features = ['odl-base-all', 'odl-restconf', 'odl-ovsdb-openstack', 'odl-dlux-core', 'odl-dlux-node', 'odl-dlux-yangui', 'odl-mdsal-apidocs']
  $karaf_odl_cluster_features = ['odl-mdsal-clustering', 'odl-openflowplugin-flow-services']

  $java_package = $operatingsystem ? {
    'CentOS' => 'java-1.7.0-openjdk',
    'Ubuntu' => 'openjdk-7-jre-headless',
  }
  $nodes_hash = hiera('nodes', {})
  $roles = node_roles($nodes_hash, hiera('uid'))

  if ( member($roles, 'controller') and $opendaylight::odl_settings['cluster'] ) or member($roles, 'primary-controller') {

    if $opendaylight::odl_settings['cluster'] {
      $odl_features = union($karaf_odl_cluster_features, $karaf_odl_features)
      $features = union($karaf_default_features, $odl_features)
    } else {
      $features = union($karaf_default_features, $karaf_odl_features)
    }

    firewall {'215 odl':
      port   => [ $opendaylight::rest_api_port, 2550, 2551, 6640, 6653, 8181, 8101],
      proto  => 'tcp',
      action => 'accept',
      before => Service['opendaylight'],
    }

    package { 'java-jre':
      ensure => installed,
      name   => $java_package,
    }

    package { 'opendaylight':
      ensure  => installed,
      require => Package['java-jre'],
    }

    service { 'opendaylight' :
      ensure  => running,
      enable  => true,
      require => File[
                      '/opt/opendaylight/configuration/tomcat-server.xml',
                      '/opt/opendaylight/etc/jetty.xml',
                      '/opt/opendaylight/etc/custom.properties',
                      '/opt/opendaylight/etc/org.apache.karaf.features.cfg'],
    }

    debug("Set odl rest api port to ${tomcat_port}")

    file { '/opt/opendaylight/configuration/tomcat-server.xml':
      ensure  => file,
      owner   => 'odl',
      content => template('opendaylight/tomcat-server.xml.erb'),
      require => Package['opendaylight']
    }

    file { '/opt/opendaylight/etc/jetty.xml':
      ensure  => file,
      owner   => 'odl',
      content => template('opendaylight/jetty.xml.erb'),
      require => Package['opendaylight']
    }

    file { '/opt/opendaylight/etc/custom.properties':
      ensure  => file,
      owner   => 'odl',
      content => template('opendaylight/custom.properties.erb'),
      require => Package['opendaylight']
    }

    file { '/opt/opendaylight/etc/org.apache.karaf.features.cfg':
      ensure  => file,
      owner   => 'odl',
      content => template('opendaylight/org.apache.karaf.features.cfg.erb'),
      require => Package['opendaylight']
    }

    exec { 'wait-until-odl-ready':
      command   => 'netstat -lpen --tcp | grep java |  grep 6653',
      path      => '/bin:/usr/bin',
      tries     => 100,
      try_sleep => 15,
    }

    include opendaylight::ha::cluster
    if $opendaylight::odl_settings['cluster'] {
      include opendaylight::ha::haproxy
      Service['opendaylight'] -> Class['opendaylight::ha::cluster'] -> Exec['wait-until-odl-ready']
    } else {
      Service['opendaylight'] -> Exec['wait-until-odl-ready']
    }
  }

  if $opendaylight::odl_settings['use_vxlan'] {
    firewall {'216 vxlan':
      port   => [4789],
      proto  => 'udp',
      action => 'accept',
    }
  }
}
