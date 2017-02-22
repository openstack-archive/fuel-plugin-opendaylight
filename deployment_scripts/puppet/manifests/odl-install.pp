notice('MODULAR: odl-install.pp')
include opendaylight
include firewall

class { 'opendaylight::install':
    rest_port    => $opendaylight::rest_api_port,
    bind_address => $opendaylight::node_internal_address
}

class {'opendaylight::quagga':
  before => Service['opendaylight']
}
