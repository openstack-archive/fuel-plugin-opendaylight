class opendaylight::quagga (
){
  $master_ip      = hiera('master_ip')

  firewall {'215 quagga':
    dport  => 179,
    proto  => 'tcp',
    action => 'accept',
  }

  $service_file = '/etc/systemd/system/zrpcd.service'
  file { $service_file:
    ensure  => file,
    content => template('opendaylight/zrpcd.service'),
  }

  if $::operatingsystem == 'Ubuntu' {
    exec { 'install_quagga':
      command => "curl http://${master_ip}:8080/plugins/opendaylight-1.0/deployment_scripts/install_quagga.sh | bash -s",
      path    => '/usr/bin:/usr/sbin:/bin:/sbin',
      timeout => 0,
      require => File[$service_file],
      before  => Service['zrpcd']
    }
    service {'zrpcd':
      ensure => running
    }
  }
}
