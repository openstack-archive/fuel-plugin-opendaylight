include opendaylight
include firewall

class { 'opendaylight::service':
    rest_port    => $opendaylight::rest_api_port,
    bind_address => $opendaylight::node_internal_address
}
