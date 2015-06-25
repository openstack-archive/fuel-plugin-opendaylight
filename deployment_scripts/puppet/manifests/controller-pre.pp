$java_package = $operatingsystem ? {
  'CentOS' => 'java-1.7.0-openjdk',
  'Ubuntu' => 'openjdk-7-jre-headless',
}

package { 'java-jre':
  ensure => installed,
  name   => $java_package,
}

package { 'opendaylight':
  ensure  => installed,
  require => Package['java-jre'],
}
