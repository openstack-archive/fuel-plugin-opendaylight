$odl = hiera('opendaylight')

service { 'neutron-server':
  ensure => stopped,
}

package {'python-networking-odl':
  ensure => installed,
}

if $odl['enable_l3_odl'] {
  neutron_config { 'DEFAULT/service_plugins': value => 'networking_odl.l3.l3_odl.OpenDaylightL3RouterPlugin,neutron.services.metering.metering_plugin.MeteringPlugin'; }
}
