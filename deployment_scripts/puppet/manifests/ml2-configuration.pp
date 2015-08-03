include opendaylight

$address = hiera('management_vip')
$port = $opendaylight::rest_api_port
neutron_plugin_ml2 {
  'ml2/mechanism_drivers':      value => 'opendaylight';
  'ml2_odl/password':           value => 'admin';
  'ml2_odl/username':           value => 'admin';
  'ml2_odl/url':                value => "http://${address}:${port}/controller/nb/v2/neutron";
}
