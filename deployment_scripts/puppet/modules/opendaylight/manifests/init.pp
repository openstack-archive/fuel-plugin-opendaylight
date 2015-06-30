class opendaylight {
  $odl_settings = hiera('opendaylight')
  $nodes_hash = hiera('nodes')
  $primary_controller_hash = filter_nodes($nodes_hash,'role','primary-controller')
  $node = filter_nodes($nodes_hash,'name',$::hostname)

  $rest_api_port = $odl_settings['rest_api_port']
  $manager_ip_address = $primary_controller_hash[0]['internal_address']
  $node_private_address = $node[0]['private_address']
  $node_internal_address = $node[0]['internal_address']
}
