include opendaylight

$address = hiera('management_vip')
$port = $opendaylight::rest_api_port
$vni_start = $opendaylight::odl_settings['vni_range_start']
$vni_end = $opendaylight::odl_settings['vni_range_end']

$network_scheme = hiera('network_scheme', {})
prepare_network_config($network_scheme)

neutron_plugin_ml2 {
  'ml2/mechanism_drivers':      value => 'opendaylight';
  'ml2_odl/password':           value => 'admin';
  'ml2_odl/username':           value => 'admin';
  'ml2_odl/url':                value => "http://${address}:${port}/controller/nb/v2/neutron";
}

if $opendaylight::odl_settings['use_vxlan'] {
  neutron_plugin_ml2 {
    'ml2/tenant_network_types':   value => 'vxlan';
    'ml2_type_vxlan/vni_ranges':   value => "${vni_start}:${vni_end}";
  }

  $iface = get_network_role_property('neutron/mesh', 'phys_dev')
  $net_mtu = get_transformation_property('mtu', $iface[0])
  if $net_mtu {
    $mtu = $net_mtu - 50
  } else {
    $mtu = 1450
  }

  neutron_config {
    'DEFAULT/network_device_mtu':  value => $mtu;
  }

  file { '/etc/neutron/dnsmasq-neutron.conf':
      owner   => 'root',
      group   => 'root',
      content => template('openstack/neutron/dnsmasq-neutron.conf.erb'),
  }
}
