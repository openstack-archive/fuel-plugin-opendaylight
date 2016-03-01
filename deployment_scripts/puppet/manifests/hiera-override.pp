notice('MODULAR: hiera-override')
include opendaylight
class { '::opendaylight::hiera_override': }
