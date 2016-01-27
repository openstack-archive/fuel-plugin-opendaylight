class opendaylight {
  $odl_settings = hiera('opendaylight')
  $nodes_hash = hiera('nodes')
  $odl_controller_hash = filter_nodes($nodes_hash,'role','opendaylight')
  $node = filter_nodes($nodes_hash,'name',$::hostname)
  $odl = hiera('opendaylight')
  if $odl['use_external_odl'] {
    $manager_ip_address = $odl['rest_api_ip']
    $odl_management_vip = $odl['rest_api_ip']
  } else {
    $manager_ip_address = $odl_controller_hash[0]['internal_address']
    $odl_management_vip = hiera('management_vip')
  }
  $rest_api_port = $odl_settings['rest_api_port']
  $node_private_address = $node[0]['private_address']
  $node_internal_address = $node[0]['internal_address']
}
