class opendaylight::vxgpe {
  firewall {'215 vxlan-gpe tcp':
    dport   => [ 6633 ],
    proto  => 'tcp',
    action => 'accept',
  }
  firewall {'215 vxlan-gpe udp':
    dport   => [ 6633 ],
    proto  => 'udp',
    action => 'accept',
  }
}