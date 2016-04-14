class opendaylight {
  $odl_settings = hiera('opendaylight')
  $network_metadata = hiera_hash('network_metadata')
  $node_uid = hiera('uid')
  $rest_api_port = $odl_settings['rest_api_port']
  $jetty_port = $odl_settings['metadata']['jetty_port']
  $odl_nodes_hash = get_nodes_hash_by_roles($network_metadata, ['opendaylight'])
  $odl_mgmt_ips_hash = get_node_to_ipaddr_map_by_network_role($odl_nodes_hash, 'management')
  $odl_mgmt_ips = values($odl_mgmt_ips_hash)
  $odl_nodes_names = keys($odl_mgmt_ips_hash)
  $node_internal_address = $odl_mgmt_ips_hash["node-${node_uid}"]
}
