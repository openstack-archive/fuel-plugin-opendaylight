class opendaylight::install (
  $rest_port = $opendaylight::rest_api_port,
  $bind_address = undef,
) inherits opendaylight {

  $management_vip = hiera('management_vip')
  $conf_dir = '/opt/opendaylight/etc'
  $jetty_port = $opendaylight::jetty_port
  $odl_package = $opendaylight::odl_settings['deb_version']
  $java_min_mem = $opendaylight::odl_settings['java_min_mem']
  $java_max_mem = $opendaylight::odl_settings['java_max_mem']
  $java_extra_opts = $opendaylight::odl_settings['java_extra_opts']

  $manage_l3_traffic = $opendaylight::odl_settings['enable_l3_odl'] ? {
    true    => 'yes',
    default => 'no',
  }

  package { 'opendaylight':
    ensure  => $odl_package,
  }

  #Temporary solution until number of allowed open files
  #will be fixed in main systemd service file
  file {'/etc/systemd/system/opendaylight.service.d':
    ensure => directory,
  } ->
  file {'/etc/systemd/system/opendaylight.service.d/override.conf':
    ensure  => file,
    content => template('opendaylight/override.conf.erb'),
  } ~>
  exec {'systemctl-daemon-reload':
    refreshonly => true,
    command     => 'systemctl daemon-reload',
    path        => ['/bin', '/user/bin'],
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
  file { '/opt/opendaylight/bin/setenv':
    ensure  => file,
    owner   => 'odl',
    mode    => '0755',
    content => template('opendaylight/setenv.erb')
  }

  $karaf_custom_properties_file = {
    'path' => "${conf_dir}/custom.properties",
    'ensure' => 'present',
    'key_val_separator' => '=',
  }
  $karaf_custom_properties = {
    '' => {
      'ovsdb.of.version' => '1.3',
      'ovsdb.l3.fwd.enabled' => $manage_l3_traffic,
    }
  }

  create_ini_settings($karaf_custom_properties, $karaf_custom_properties_file)

  $enabled_features = odl_karaf_features($opendaylight::odl_settings)

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
  File <||> ~>
  Service['opendaylight']
}
