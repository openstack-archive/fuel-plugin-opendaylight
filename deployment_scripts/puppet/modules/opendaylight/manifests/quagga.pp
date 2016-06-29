class opendaylight::quagga (
){
  # quagga
  package { ['opnfv-quagga', 'libcapnp-0.5.99', 'python-pycapnp', 'python-thriftpy']:
    ensure => installed,
  }
  $bgp_conf = "/usr/lib/quagga/qthrift/bgpd.conf"
  ini_setting { 'bgp_password':
    ensure  => present,
    setting => 'bgp_password',
    value   => 'sdncbgpc',
    path    => $bgp_conf,
  }
}
