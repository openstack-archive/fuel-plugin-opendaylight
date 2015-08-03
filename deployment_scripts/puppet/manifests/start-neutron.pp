include opendaylight

$access_hash = hiera('access', {})
$keystone_admin_tenant = $access_hash[tenant]
$neutron_config = hiera_hash('quantum_settings')
$segmentation_type = $neutron_config['L2']['segmentation_type']
$nets = $neutron_config['predefined_networks']
$odl = hiera('opendaylight')
$nodes_hash = hiera('nodes', {})
$roles = node_roles($nodes_hash, hiera('uid'))

if $segmentation_type != 'vlan' {
  if $segmentation_type =='gre' {
    $network_type = 'gre'
  } else {
    $network_type = 'vxlan'
  }
} else {
  $network_type = 'vlan'
}

service { 'neutron-server':
  ensure => running,
}

if member($roles, 'primary-controller') {
  exec {'refresh-dhcp-agent':
    command   => 'crm resource restart p_neutron-dhcp-agent',
    path      => '/usr/bin:/usr/sbin',
    tries     => 3,
    try_sleep => 10,
  } ->
  exec {'refresh-metadata-agent':
    command   => 'crm resource restart p_neutron-metadata-agent',
    path      => '/usr/bin:/usr/sbin',
    tries     => 3,
    try_sleep => 10,
  }
  unless $odl['enable_l3_odl'] {
    exec {'refresh-l3-agent':
      command   => 'crm resource restart p_neutron-l3-agent',
      path      => '/usr/bin:/usr/sbin',
      tries     => 3,
      try_sleep => 10,
    }
  }

  if $nets and !empty($nets) {

    Service<| title == 'neutron-server' |> ->
      Openstack::Network::Create_network <||>

    Service<| title == 'neutron-server' |> ->
      Openstack::Network::Create_router <||>

    openstack::network::create_network{'net04':
      netdata           => $nets['net04'],
      segmentation_type => $network_type,
    } ->
    openstack::network::create_network{'net04_ext':
      netdata           => $nets['net04_ext'],
      segmentation_type => 'local',
    } ->
    openstack::network::create_router{'router04':
      internal_network => 'net04',
      external_network => 'net04_ext',
      tenant_name      => $keystone_admin_tenant
    }

  }
}
