$odl = hiera('opendaylight')
unless $odl['use_external_odl']{
    class { 'opendaylight::service':}
}
