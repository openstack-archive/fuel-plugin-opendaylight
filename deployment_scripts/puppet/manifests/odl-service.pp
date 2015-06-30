include opendaylight
include firewall

class { 'opendaylight::service':
    tomcat_port  => $opendaylight::rest_api_port,
    bind_address => $opendaylight::node_internal_address
}
