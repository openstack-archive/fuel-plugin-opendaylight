class opendaylight::hiera_override {
  $override_file = '/etc/hiera/override/opendaylight.yaml'
  odl_hiera_overrides($override_file)

  file_line {'opendaylight_hiera_override':
    path  => '/etc/hiera.yaml',
    line  => '    - override/opendaylight',
    after => '    - "override/module/%{calling_module}"',
  }
}
