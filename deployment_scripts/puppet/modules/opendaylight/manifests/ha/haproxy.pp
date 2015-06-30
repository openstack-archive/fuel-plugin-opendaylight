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

  Haproxy::Service        { use_include => true }
  Haproxy::Balancermember { use_include => true }

  $public_vip = hiera('public_vip')
  $management_vip = hiera('management_vip')
  $nodes_hash = hiera('nodes')
  $primary_controller_nodes = filter_nodes($nodes_hash,'role','primary-controller')
  $controllers = concat($primary_controller_nodes, filter_nodes($nodes_hash,'role','controller'))

  Opendaylight::Ha::Haproxy_service {
    server_names        => filter_hash($controllers, 'name'),
    ipaddresses         => filter_hash($controllers, 'internal_address'),
    public_virtual_ip   => $public_vip,
    internal_virtual_ip => $management_vip,
  }

  opendaylight::ha::haproxy_service { 'odl-jetty':
    public                 => true,
    order                  => '216',
    listen_port            => '8181',
    balancermember_port    => '8181',

    haproxy_config_options => {
      'option'         => ['httpchk /dlux/index.html', 'httplog'],
      'timeout client' => '3h',
      'timeout server' => '3h',
      'balance'        => 'source',
      'mode'           => 'http'
    },

    balancermember_options => 'check inter 5000 rise 2 fall 3',
  }

  opendaylight::ha::haproxy_service { 'odl-tomcat':
    public                 => true,
    order                  => '215',
    listen_port            => $opendaylight::rest_api_port,
    balancermember_port    => $opendaylight::rest_api_port,

    haproxy_config_options => {
      'option'         => ['httpchk /apidoc/explorer', 'httplog'],
      'timeout client' => '3h',
      'timeout server' => '3h',
      'balance'        => 'source',
      'mode'           => 'http'
    },

    balancermember_options => 'check inter 5000 rise 2 fall 3',
  }

  exec { 'haproxy reload':
    command   => 'export OCF_ROOT="/usr/lib/ocf"; (ip netns list | grep haproxy) && ip netns exec haproxy /usr/lib/ocf/resource.d/fuel/ns_haproxy reload',
    path      => '/usr/bin:/usr/sbin:/bin:/sbin',
    logoutput => true,
    provider  => 'shell',
    tries     => 10,
    try_sleep => 10,
    returns   => [0, ''],
  }

  Haproxy::Listen <||> -> Exec['haproxy reload']
  Haproxy::Balancermember <||> -> Exec['haproxy reload']

}
