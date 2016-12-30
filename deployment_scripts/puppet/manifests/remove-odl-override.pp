notice('MODULAR: remove-odl-override.pp')

file { '/etc/hiera/plugins/opendaylight.yaml':
  ensure => absent,
}
