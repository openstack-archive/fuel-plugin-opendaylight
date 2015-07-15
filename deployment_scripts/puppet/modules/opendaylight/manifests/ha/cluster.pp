class opendaylight::ha::cluster {
  $nodes_hash = hiera('nodes')
  $primary_controller_nodes = filter_nodes($nodes_hash,'role','primary-controller')
  $controllers = concat($primary_controller_nodes, filter_nodes($nodes_hash,'role','controller'))
  $server_names = filter_hash($controllers, 'name')
  $ipaddresses = filter_hash($controllers, 'internal_address')
  $node = filter_nodes($nodes_hash,'name',$::hostname)
  $node_name = join(filter_hash($node, 'name'), '')
  $node_internal_address = join(filter_hash($node, 'internal_address'), '')


  exec {'enable_jolokia':
    command   => '/opt/opendaylight/bin/client -u karaf "bundle:install -s mvn:org.jolokia/jolokia-osgi/1.1.5"',
    tries     => 30,
    try_sleep => 10,
  } ->
  file {'/opt/opendaylight/configuration/initial/akka.conf':
    ensure  => file,
    owner   => 'odl',
    content => template('opendaylight/akka.conf.erb'),
  } ->
  file {'/opt/opendaylight/configuration/initial/module-shards.conf':
    ensure  => file,
    owner   => 'odl',
    content => template('opendaylight/module-shards.conf.erb')
  } ->
  exec {'restart-odl':
    command => 'service opendaylight stop; sleep 10; service opendaylight start',
    path    => '/bin:/usr/sbin:/usr/bin:/sbin',
  }
}
