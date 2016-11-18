#
# Modify default network schema.
# ODL use only br-int and br-ex bridges and both of them
# should be created on OVS.
# Override hiera hierarchy is not enough because of default hash deep merge policy.
#
module Puppet::Parser::Functions
  newfunction(:odl_network_scheme, :type => :rvalue) do |args|
    # override network_scheme
    odl = function_hiera(['opendaylight'])
    network_scheme = function_hiera(['network_scheme'])

    delete_bridges = ['br-prv']

    debug "ODL network before transformation: #{network_scheme}"

    endpoints = network_scheme['endpoints']
    transformations = network_scheme['transformations']
    transformations.delete_if { |action| action['action'] == 'add-br' and delete_bridges.include?(action['name']) }
    transformations.delete_if { |action| action['action'] == 'add-patch' and not (action['bridges'] & delete_bridges).empty? }
    transformations.delete_if { |action| action['action'] == 'add-port' and delete_bridges.include?(action['bridge']) }

    if not odl['enable_netvirt']
      debug "Changing network_scheme for the non netvirt case."
      # Modify only once
      if not endpoints.has_key? 'br-ex-lnx'
        transformations.each { |action| action['name'] = 'br-ex-lnx' if (action['action'] == 'add-br' and action['name'] == 'br-ex') }
        transformations.each { |action| action['bridge'] = 'br-ex-lnx' if (action['action'] == 'add-port' and action['bridge'] == 'br-ex') }
        transformations.each { |action| action['bridge'] = 'br-ex-lnx' if (action['action'] == 'add-bond' and action['bridge'] == 'br-ex') }
      end

      transformations.each { |action| action['name'] = 'br-ex' if (action['action'] == 'add-br' and action['name'] == 'br-floating') }
      transformations.each { |action| action['bridge'] = 'br-ex' if (action['action'] == 'add-port' and action['bridge'] == 'br-floating') }

      transformations.each { |action| action['bridges'] = ['br-ex', 'br-ex-lnx'] if (action['action'] == 'add-patch' and action['bridges'] == ['br-floating', 'br-ex']) }

      roles = network_scheme['roles']
      roles.each { |role,bridge| roles[role] = 'br-ex-lnx' if bridge == 'br-ex' }
      roles['neutron/private'] = 'br-aux' if roles.has_key?('neutron/private')
      roles['neutron/floating'] = 'br-ex' if roles.has_key?('neutron/floating')

      if endpoints.has_key? 'br-ex' and not endpoints.has_key? 'br-ex-lnx'
        endpoints['br-ex-lnx'] = endpoints.delete 'br-ex'
      end

      if endpoints.has_key? 'br-floating'
         endpoints['br-ex'] = endpoints.delete 'br-floating'
      end

      if endpoints.has_key? 'br-prv'
         endpoints['br-aux'] = endpoints.delete 'br-prv'
      end
    else
      debug "Changing network_scheme for the bgpvpn case"
      if endpoints.has_key? 'br-prv'
         endpoints.delete 'br-prv'
      end
    end
    debug "ODL network after transformation: #{network_scheme}"
    network_scheme
  end
end
