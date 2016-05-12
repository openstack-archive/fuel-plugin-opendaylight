notice('MODULAR: odl-install.pp')
include opendaylight
include firewall

class { 'opendaylight::install': }
