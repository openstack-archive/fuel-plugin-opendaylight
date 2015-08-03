$nodes_hash = hiera('nodes', {})
$roles = node_roles($nodes_hash, hiera('uid'))
$odl = hiera('opendaylight')

$ovs_agent_name = $operatingsystem ? {
  'CentOS' => 'neutron-openvswitch-agent',
  'Ubuntu' => 'neutron-plugin-openvswitch-agent',
}

if member($roles, 'primary-controller') {
  cs_resource { "p_${ovs_agent_name}":
    ensure => absent,
  }

  if $odl['enable_l3_odl'] {
    cs_resource { 'p_neutron-l3-agent':
      ensure => absent,
    }
  }

} else {
  service {$ovs_agent_name:
    ensure => stopped,
    enable => false,
  }
}
