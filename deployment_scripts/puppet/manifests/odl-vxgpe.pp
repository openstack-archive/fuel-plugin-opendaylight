notice('MODULAR: odl-vxgpe.pp')
include firewall

class { 'opendaylight::vxgpe': }