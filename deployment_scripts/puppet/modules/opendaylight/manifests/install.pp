class opendaylight::install (
  $rest_port = $opendaylight::rest_api_port,
  $odl_nodes_names = $opendaylight::odl_nodes_names,
  $odl_nodes_ips   = $opendaylight::odl_mgmt_ips,
  $bind_address = $opendaylight::node_internal_address,
) {

  $management_vip = hiera('management_vip')
  $odl = hiera('opendaylight')
  $conf_dir = '/opt/opendaylight/etc'
  $jetty_port = $opendaylight::jetty_port
  $odl_nodes_number = count($odl_nodes_ips)
  $node_hostname = hiera('node_name')

  if $odl['enable_l3_odl'] {
    $manage_l3_traffic = 'yes'
  } else {
    $manage_l3_traffic = 'no'
  }

  package { 'opendaylight':
    ensure  => installed,
  }

  package {'opnfv-quagga':
    ensure => installed,
  }

  firewall {'215 odl':
    port   => [ 2550, 2551, $rest_port, 6633, 6640, 6653, $jetty_port, 8101],
    proto  => 'tcp',
    action => 'accept',
  }

  service { 'opendaylight' :
    ensure => running,
    enable => true,
  }

  debug("Set odl rest api port to ${rest_port}")

  file { "${conf_dir}/jetty.xml":
    ensure  => file,
    owner   => 'odl',
    content => template('opendaylight/jetty.xml.erb')
  }

  $karaf_custom_properties_file = {
    'path' => "${conf_dir}/custom.properties",
    'ensure' => 'present',
    'key_val_separator' => '=',
  }
  $karaf_custom_properties = {
    '' => {
      'of.address' => $bind_address,
      'of.listenPort' => '6653',
      'ovsdb.of.version' => '1.3',
      'ovsdb.l3.fwd.enabled' => $manage_l3_traffic,
    }
  }

  create_ini_settings($karaf_custom_properties, $karaf_custom_properties_file)

  $enabled_features = odl_karaf_features()

  ini_setting {'karaf_features':
    ensure            => present,
    section           => '',
    key_val_separator => '=',
    path              => "${conf_dir}/org.apache.karaf.features.cfg",
    setting           => 'featuresBoot',
    value             => $enabled_features,
  }

  if $odl_nodes_number >= 2 {
    #HA configuration
    file {'/opt/opendaylight/configuration/initial':
      ensure => 'directory',
      owner  => 'odl',
      group  => 'odl'
    }

    file {'/opt/opendaylight/configuration/initial/akka.conf':
      ensure  => file,
      owner   => 'odl',
      content => template('opendaylight/akka.conf.erb'),
      require => File['/opt/opendaylight/configuration/initial'],
    }
    file {'/opt/opendaylight/configuration/initial/module-shards.conf':
      ensure  => file,
      owner   => 'odl',
      content => template('opendaylight/module-shards.conf.erb'),
      require => File['/opt/opendaylight/configuration/initial'],
    }

  }

  Package['opendaylight'] ->
  Ini_setting <||> ->
  Firewall <||> ->
  File <||> ->
  Service['opendaylight']
}
