notice('MODULAR: odl-ml2.pp')

class neutron {}
class { 'neutron' :}

$override_configuration = hiera_hash(configuration, {})
$override_configuration_options = { create => true }

override_resources { 'odl-ml2-override':
  configuration => $override_configuration,
  options       => $override_configuration_options,
}


include ::neutron::params

$node_name = hiera('node_name')
$neutron_primary_controller_roles = hiera('neutron_primary_controller_roles', ['primary-controller'])
$neutron_compute_roles            = hiera('neutron_compute_nodes', ['compute'])
$primary_controller               = roles_include($neutron_primary_controller_roles)
$compute                          = roles_include($neutron_compute_roles)

$neutron_config = hiera_hash('neutron_config')
$neutron_server_enable = pick($neutron_config['neutron_server_enable'], true)
$neutron_nodes = hiera_hash('neutron_nodes')

$dpdk_config = hiera_hash('dpdk', {})
$enable_dpdk = pick($dpdk_config['enabled'], false)

$management_vip         = hiera('management_vip')
$service_endpoint       = hiera('service_endpoint', $management_vip)
$ssl_hash               = hiera_hash('use_ssl', {})
$internal_auth_protocol = get_ssl_property($ssl_hash, {}, 'keystone', 'internal', 'protocol', 'http')
$internal_auth_address  = get_ssl_property($ssl_hash, {}, 'keystone', 'internal', 'hostname', [$service_endpoint])

$auth_api_version   = 'v2.0'
$identity_uri       = "${internal_auth_protocol}://${internal_auth_address}:5000"
$auth_url           = "${identity_uri}/${auth_api_version}"
$auth_password      = $neutron_config['keystone']['admin_password']
$auth_user          = pick($neutron_config['keystone']['admin_user'], 'neutron')
$auth_tenant        = pick($neutron_config['keystone']['admin_tenant'], 'services')
$auth_region        = hiera('region', 'RegionOne')
$auth_endpoint_type = 'internalURL'

# Synchronize database after plugin was configured
if $primary_controller {
  include ::neutron::db::sync

  Override_resources['odl-ml2-override'] -> Exec['neutron-db-sync']

  notify{"Trigger neutron-db-sync": } ~> Exec['neutron-db-sync']
}

if $node_name in keys($neutron_nodes) {
  if $neutron_server_enable {
    $service_ensure = 'running'
  } else {
    $service_ensure = 'stopped'
  }

  service { 'neutron-server':
    name       => $::neutron::params::server_service,
    enable     => $neutron_server_enable,
    ensure     => $service_ensure,
    hasstatus  => true,
    hasrestart => true,
    tag        => 'neutron-service',
  }

  exec { 'waiting-for-neutron-api':
    environment => [
      "OS_TENANT_NAME=${auth_tenant}",
      "OS_USERNAME=${auth_user}",
      "OS_PASSWORD=${auth_password}",
      "OS_AUTH_URL=${auth_url}",
      "OS_REGION_NAME=${auth_region}",
      "OS_ENDPOINT_TYPE=${auth_endpoint_type}",
    ],
    path        => '/usr/sbin:/usr/bin:/sbin:/bin',
    tries       => '30',
    try_sleep   => '4',
    command     => 'neutron net-list --http-timeout=4 2>&1 > /dev/null',
    provider    => 'shell',
    subscribe   => Service['neutron-server'],
    refreshonly => true,
  }

}

# Stub for upstream neutron manifests
package { 'neutron':
  name   => 'binutils',
  ensure => 'installed',
}
