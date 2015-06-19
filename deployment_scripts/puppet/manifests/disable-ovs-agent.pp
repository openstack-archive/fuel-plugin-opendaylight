$role = hiera('role')

$ovs_agent_name = $operatingsystem ? {
  'CentOS' => 'neutron-openvswitch-agent',
  'Ubuntu' => 'neutron-plugin-openvswitch-agent',
}

if $role == 'primary-controller' {
  cs_resource { "p_${ovs_agent_name}":
    ensure => absent,
  }
} else {
  service {$ovs_agent_name:
    ensure => stopped,
    enable => false,
  }
}
