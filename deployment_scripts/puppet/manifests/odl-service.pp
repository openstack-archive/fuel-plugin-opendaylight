include opendaylight
include firewall

class { 'opendaylight::service':
    port => $opendaylight::rest_api_port,
}
