class opendaylight::hiera_override {
  $override_file = '/etc/hiera/plugins/opendaylight.yaml'
  $roles = hiera('roles')
  odl_hiera_overrides($override_file, $roles)
}
