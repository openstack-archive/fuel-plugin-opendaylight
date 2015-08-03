include opendaylight

$network_scheme = hiera('network_scheme', {})
$neutron_config = hiera_hash('quantum_settings')
prepare_network_config($network_scheme)


$ovs_service_name = $operatingsystem ? {
  'CentOS' => 'openvswitch',
  'Ubuntu' => 'openvswitch-switch',
}

exec { 'stop-ovs-service':
  command   => "service ${ovs_service_name} stop",
  path      => '/bin:/usr/sbin:/usr/bin:/sbin',
  logoutput => true,
}

exec { 'remove-ovs-logs':
  command => 'rm -f /var/log/openvswitch/*',
  path    => '/bin:/usr/sbin:/usr/bin',
}
exec { 'remove-ovs-db':
  command => 'rm -f /etc/openvswitch/*; rm -f /etc/openvswitch/.conf.db.~lock~',
  path    => '/bin:/usr/sbin:/usr/bin',
}
exec { 'ovs-set-manager':
  command => "ovs-vsctl set-manager tcp:${opendaylight::manager_ip_address}:6640",
  path    => '/usr/bin'
}

if $neutron_config['L2']['segmentation_type'] != 'vlan' {
  $net_role_property = 'neutron/mesh'
  $tunneling_ip = get_network_role_property($net_role_property, 'ipaddr')
  exec { 'ovs-set-tunnel-endpoint':
    command => "ovs-vsctl set Open_vSwitch $(ovs-vsctl show | head -n 1) other_config={'local_ip'='${tunneling_ip}'}",
    path    => '/usr/bin',
    require => Exec['ovs-set-manager']
  }
} else {
  $net_role_property = 'neutron/private'
  $iface = get_network_role_property($net_role_property, 'phys_dev')
  exec { 'ovs-br-int-to-phy':
    command   => "ovs-vsctl --may-exist add-port br-int ${iface} -- set Interface ${iface} type=internal",
    path      => '/usr/bin',
    tries     => 30,
    try_sleep => 5,
    require   => Exec['ovs-set-manager']
  }
  exec { 'ovs-set-provider-mapping':
    command => "ovs-vsctl set Open_vSwitch $(ovs-vsctl show | head -n 1) other_config:provider_mappings=physnet2:${iface}",
    path    => '/usr/bin',
    require => Exec['ovs-br-int-to-phy']
  }
}

service { $ovs_service_name:
  ensure => running,
}

Exec['stop-ovs-service'] ->
Exec['remove-ovs-logs'] ->
Exec['remove-ovs-db'] ->
Service[$ovs_service_name] ->
Exec['ovs-set-manager']
