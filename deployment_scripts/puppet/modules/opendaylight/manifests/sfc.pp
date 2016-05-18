class opendaylight::sfc {
    include opendaylight
    $management_vip = hiera('management_vip')
    $odl = hiera('opendaylight')
    $rest_port = $odl['rest_api_port']

    if $odl['enable_sfc'] {
        if $odl['sfc_class']=='ncr' {
            if roles_include(['primary-controller']) {
                exec { 'odl_netvirt_coexistence':
                command   => "/usr/bin/curl -i -u admin:admin \
-H 'Content-type: application/json' \
-X PUT -d '{\"netvirt-providers-config\":{\"table-offset\":\"1\"}}' \
http://${management_vip}:${rest_port}/restconf/config/netvirt-providers-config:netvirt-providers-config",
                }
                exec { 'odl_sfc_coexistence':
                command   => "/usr/bin/curl -i -u admin:admin \
-H 'Content-type: application/json' -X PUT -d \
'{\"sfc-of-renderer-config\":{\"sfc-of-table-offset\":\"150\",\"sfc-of-app-egress-table-offset\":\"11\"}}' \
http://${management_vip}:${rest_port}/restconf/config/sfc-of-renderer:sfc-of-renderer-config",
                }
            }
        }
    }
}
