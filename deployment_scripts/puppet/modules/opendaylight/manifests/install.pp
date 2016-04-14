class opendaylight::install (
  $rest_port = $opendaylight::rest_api_port,
  $bind_address = undef,
) {

  $management_vip = hiera('management_vip')
  $odl = hiera('opendaylight')
  $conf_dir = '/opt/opendaylight/etc'
  $jetty_port = $opendaylight::jetty_port

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
    port   => [ $opendaylight::rest_api_port, 6633, 6640, 6653, $jetty_port, 8101],
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

  Package['opendaylight'] ->
  Ini_setting <||> ->
  Firewall <||> ->
  File <||> ->
  Service['opendaylight']
}
