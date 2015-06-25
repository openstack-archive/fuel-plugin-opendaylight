exec { 'add-br-floating':
  command => 'ovs-vsctl add-br br-floating',
  unless  => 'ovs-vsctl br-exists br-floating',
  path    => '/usr/bin',
} ->
exec { 'set-br-floating-id':
  command => 'ovs-vsctl br-set-external-id br-floating bridge-id br-floating',
  path    => '/usr/bin',
} ->
exec { 'add-floating-patch':
  command => 'ovs-vsctl --may-exist add-port br-floating p_br-floating-0 -- set Interface p_br-floating-0 type=internal',
  path    => '/usr/bin',
}
