#
#    Copyright 2015 Mirantis, Inc.
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.
#
class opendaylight::ha::haproxy {

  include opendaylight

  $public_vip = hiera('public_vip')
  $management_vip = hiera('management_vip')
  $api_port = $opendaylight::rest_api_port
  $jetty_port = $opendaylight::jetty_port

  # defaults for any haproxy_service within this class
  Openstack::Ha::Haproxy_service {
      internal_virtual_ip => $management_vip,
      ipaddresses         => $opendaylight::odl_mgmt_ips,
      public_virtual_ip   => $public_vip,
      server_names        => $opendaylight::odl_nodes_names,
      public              => true,
      internal            => true,
  }

  openstack::ha::haproxy_service { 'odl-jetty':
    order                  => '216',
    listen_port            => $jetty_port,
    haproxy_config_options => {
      'option'         => ['httpchk /index.html', 'httplog'],
      'timeout client' => '3h',
      'timeout server' => '3h',
      'balance'        => 'source',
      'mode'           => 'http'
    },
    balancermember_options => 'check inter 2000 fall 3',
  }

  openstack::ha::haproxy_service { 'odl-neutron-endpoint':
    order                  => '215',
    listen_port            => $api_port,
    haproxy_config_options => {
      'option'         => ['httpchk /index', 'httplog'],
      'timeout client' => '3h',
      'timeout server' => '3h',
      'balance'        => 'source',
      'mode'           => 'http'
    },
    balancermember_options => 'check inter 5000 rise 2 fall 3',
  }
}
