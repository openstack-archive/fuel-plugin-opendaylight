class opendaylight::service (
  $rest_port = 8282,
  $bind_address = undef
) {

  $nodes_hash = hiera('nodes', {})
  $roles = node_roles($nodes_hash, hiera('uid'))
  $management_vip = hiera('management_vip')

  $karaf_default_features = ['config',
                             'standard',
                             'region',
                             'package',
                             'kar',
                             'ssh',
                             'management']
  $karaf_odl_features     = ['odl-restconf-all',
                             'odl-aaa-authn',
                             'odl-dlux-all',
                             'odl-mdsal-apidocs',
                             'odl-ovsdb-openstack']
  $karaf_odl_gbp_features = ['odl-groupbasedpolicy-base',
                             'odl-groupbasedpolicy-ofoverlay',
                             'odl-groupbasedpolicy-ui',
                             'odl-groupbasedpolicy-uibackend']
  $karaf_odl_sfc_features = ['odl-sfc-core',
                             'odl-sfc-model',
                             'odl-sfc-netconf',
                             'odl-sfc-ovs',
                             'odl-sfc-provider',
                             'odl-sfc-sb-rest',
                             'odl-sfc-ui',
                             'odl-sfclisp',
                             'odl-sfcofl2']

  if member($roles, 'primary-controller') {

    if $opendaylight::odl_settings['deploy_sfc'] {
      $fu1      = union($karaf_default_features,
                        $karaf_odl_features)
      $fu2      = union($karaf_odl_gbp_features,
                        $karaf_odl_sfc_features)
      $features = union($fu1, $fu2)
    } else {
      $features = union($karaf_default_features,
                        $karaf_odl_features)
    }

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

  if $opendaylight::odl_settings['use_vxlan'] {
    firewall {'216 vxlan':
      port   => [4789],
      proto  => 'udp',
      action => 'accept',
    }
  }
}
