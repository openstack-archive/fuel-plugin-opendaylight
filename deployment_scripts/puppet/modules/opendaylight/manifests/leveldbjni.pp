# == Class opendaylight::leveldbjni
#
# Manages patching of JNI for leveldb on arm64.
#
# It fetches a prebuilt DEB package containing leveldbjni,
# patched so that it's properly detected by maven on arm64 systems.
#
# DEB: http://linux.enea.com/mos-repos/ubuntu/9.0/ \
#      pool/main/a/armband-odl-leveldb-fix/
# JIRA: https://jira.opnfv.org/browse/ARMBAND-114
#
class opendaylight::leveldbjni {
  case $::osfamily {
    'Debian', 'Ubuntu': {}
    default: {
      fail('Not supported on OS other than Debian based.')
    }
  }

  if ! defined(Package['armband-odl-leveldb-fix']) {
    package { 'armband-odl-leveldb-fix':
      ensure => 'present',
    }
  }
}
