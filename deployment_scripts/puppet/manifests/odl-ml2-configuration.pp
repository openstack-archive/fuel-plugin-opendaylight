notice('MODULAR: odl-ml2.pp')

include opendaylight
$use_neutron = hiera('use_neutron', false)

class neutron {}
class { 'neutron' :}

$address = hiera('management_vip')
$port = $opendaylight::rest_api_port

if $use_neutron {
  include ::neutron::params

  $node_name = hiera('node_name')
  $primary_controller = roles_include(['primary-controller'])

  $neutron_config = hiera_hash('neutron_config')
  $neutron_server_enable = pick($neutron_config['neutron_server_enable'], true)
  $neutron_nodes = hiera_hash('neutron_nodes')

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

  $network_scheme = hiera_hash('network_scheme', {})
  prepare_network_config($network_scheme)

  $neutron_advanced_config = hiera_hash('neutron_advanced_configuration', { })
  $l2_population     = try_get_value($neutron_advanced_config, 'neutron_l2_pop', false)
  $dvr               = try_get_value($neutron_advanced_config, 'neutron_dvr', false)
  $segmentation_type = try_get_value($neutron_config, 'L2/segmentation_type')

  if $compute and ! $dvr {
    $do_floating = false
  } else {
    $do_floating = true
  }

  $bridge_mappings = generate_bridge_mappings($neutron_config, $network_scheme, {
    'do_floating' => $do_floating,
    'do_tenant'   => true,
    'do_provider' => false
  })

  if $segmentation_type == 'vlan' {
    $net_role_property    = 'neutron/private'
    $iface                = get_network_role_property($net_role_property, 'phys_dev')
    $enable_tunneling = false
    $network_type = 'vlan'
    $tunnel_types = []
  } else {
    $net_role_property = 'neutron/mesh'
    $tunneling_ip      = get_network_role_property($net_role_property, 'ipaddr')
    $iface             = get_network_role_property($net_role_property, 'phys_dev')
    $physical_net_mtu  = pick(get_transformation_property('mtu', $iface[0]), '1500')
    $tunnel_id_ranges  = [try_get_value($neutron_config, 'L2/tunnel_id_ranges')]

    if $segmentation_type == 'gre' {
      $mtu_offset = '42'
      $network_type = 'gre'
    } else {
      # vxlan is the default segmentation type for non-vlan cases
      $mtu_offset = '50'
      $network_type = 'vxlan'
    }
    $tunnel_types = [$network_type]

    $enable_tunneling = true
  }

  neutron_plugin_ml2 {
    'ml2/mechanism_drivers':      value => 'opendaylight';
    'ml2_odl/password':           value => 'admin';
    'ml2_odl/username':           value => 'admin';
    'ml2_odl/url':                value => "http://${address}:${port}/controller/nb/v2/neutron";
  }


  # Synchronize database after plugin was configured
  if $primary_controller {
    include ::neutron::db::sync
    Neutron_plugin_ml2<||> ~> Exec['neutron-db-sync']
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
    } ->
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
      provider    => 'shell'
    }

  }

  # Stub for upstream neutron manifests
  package { 'neutron':
    name   => 'binutils',
    ensure => 'installed',
  }

  # override neutron options
  $override_configuration = hiera_hash('configuration', {})
  override_resources { 'neutron_plugin_ml2':
    data => $override_configuration['neutron_plugin_ml2']
  }
  override_resources { 'neutron_agent_ovs':
    data => $override_configuration['neutron_agent_ovs']
  }

}
