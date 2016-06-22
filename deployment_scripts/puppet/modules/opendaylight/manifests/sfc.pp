class opendaylight::sfc {
    include opendaylight

    $management_vip = hiera('management_vip')
    $odl = $opendaylight::odl_settings
    $rest_port = $opendaylight::rest_api_port
    $user = $odl['metadata']['default_credentials']['user']
    $password = $odl['metadata']['default_credentials']['password']

    if $odl['enable_sfc'] {
        if $odl['sfc_class']=='ncr' {
            exec { 'odl_netvirt_coexistence':
            command   => "/usr/bin/curl -i -u ${user}:${password} \
-H 'Content-type: application/json' \
-X PUT -d '{\"netvirt-providers-config\":{\"table-offset\":\"1\"}}' \
http://${management_vip}:${rest_port}/restconf/config/netvirt-providers-config:netvirt-providers-config",
                }
            exec { 'odl_sfc_coexistence':
            command   => "/usr/bin/curl -i -u ${user}:${password} \
-H 'Content-type: application/json' -X PUT -d \
'{\"sfc-of-renderer-config\":{\"sfc-of-table-offset\":\"150\",\"sfc-of-app-egress-table-offset\":\"11\"}}' \
http://${management_vip}:${rest_port}/restconf/config/sfc-of-renderer:sfc-of-renderer-config",
            }
        }
    }
}
