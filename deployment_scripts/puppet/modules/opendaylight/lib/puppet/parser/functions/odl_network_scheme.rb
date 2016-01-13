module Puppet::Parser::Functions
  newfunction(:odl_network_scheme, :type => :rvalue) do |args|
    node_roles = args[0]
    # override network_scheme
    odl = function_hiera(['opendaylight'])
    delete_bridges = ['br-floating', 'br-prv']
    debug "ODL: skip creation of those bridges: #{delete_bridges}"
    network_scheme = function_hiera(['network_scheme'])
    management_vrouter_vip = function_hiera(['management_vrouter_vip'])

    transformations = network_scheme['transformations']
    transformations.delete_if { |action| action['action'] == 'add-br' and delete_bridges.include?(action['name']) }
    transformations.delete_if { |action| action['action'] == 'add-patch' and not (action['bridges'] & delete_bridges).empty? }
    transformations.delete_if { |action| action['action'] == 'add-port' and delete_bridges.include?(action['bridge']) }

    roles = network_scheme['roles']
    roles['neutron/private'] = 'br-aux'

    endpoints = network_scheme['endpoints']
    endpoints.delete_if { |bridge, value| delete_bridges.include?(bridge) }

    transformations.each { |action| action['provider'] = 'ovs' if (action['action'] == 'add-br' and action['name'] == 'br-ex') }
    transformations.each { |action| action['provider'] = 'ovs' if (action['action'] == 'add-port' and action['bridge'] == 'br-ex') }

    roles['neutron/floating'] = 'br-ex'

    if node_roles.include?('compute') and odl['enable_l3_odl']
      endpoints.each do |bridge,value|
        if bridge == 'br-ex'
          debug 'ODL: not use br-ex as gateway on compute node'
          value.delete('gateway')
          value['IP'] = 'none'
        end
        if bridge == 'br-mgmt'
          value['gateway'] = management_vrouter_vip
        end
      end
    end
    network_scheme
  end
end
