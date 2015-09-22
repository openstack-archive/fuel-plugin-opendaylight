$ovs_version = "2.3.2-1"
if $operatingsystem == 'Ubuntu' {
	package { 'openvswitch-datapath-dkms':
		ensure => "${ovs_version}",
	}
	package { 'openvswitch-common':
		ensure => "${ovs_version}",
	}
	package { 'openvswitch-switch':
		ensure => "${ovs_version}",
		require => Package['openvswitch-common','openvswitch-datapath-dkms'],
	}
} elsif $operatingsystem == 'CentOS' {
	package { 'openvswitch':
		ensure => "${ovs_version}",
	}
}
