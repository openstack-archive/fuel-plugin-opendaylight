include opendaylight

$access_hash = hiera('access', {})
$keystone_admin_tenant = $access_hash[tenant]
$neutron_settings = hiera('quantum_settings')
$nets = $neutron_settings['predefined_networks']

$nodes_hash = hiera('nodes', {})
$roles = node_roles($nodes_hash, hiera('uid'))

$physnet = $nets['net04']['L2']['physnet']
$segment_id = $nets['net04']['L2']['segment_id']
$vm_net_l3 = $nets['net04']['L3']

if $opendaylight::odl_settings['use_vxlan'] {
  $segmentation_type = 'vxlan'
} else {
  $segmentation_type = $neutron_settings['L2']['segmentation_type']
}

$vm_net = { shared => false,
            "L2" => { network_type => $segmentation_type,
                    router_ext => false,
                    physnet => $physnet,
                    segment_id => $segment_id,
                  },
            "L3" => $vm_net_l3,
            tenant => 'admin'
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
  } ->
  exec {'refresh-l3-agent':
    command   => 'crm resource restart p_neutron-l3-agent',
    path      => '/usr/bin:/usr/sbin',
    tries     => 3,
    try_sleep => 10,
  } ->
  openstack::network::create_network{'net04':
    netdata => $vm_net,
    require => Service['neutron-server']
  } ->
  openstack::network::create_network{'net04_ext':
    netdata => $nets['net04_ext']
  } ->
  openstack::network::create_router{'router04':
    internal_network => 'net04',
    external_network => 'net04_ext',
    tenant_name      => $keystone_admin_tenant
  }
}
