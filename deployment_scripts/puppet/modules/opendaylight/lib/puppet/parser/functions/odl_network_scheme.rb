module Puppet::Parser::Functions
  newfunction(:odl_network_scheme, :arity => 2, :type => :rvalue, :doc => <<-ENDHEREDOC
    Modify/override default network scheme.
    ODL uses only br-int and br-ex bridges and both of them should be created on OVS.

    input:
      <boolean> bgpvpn enabled or not
      <hash> original network scheme

    output: overridden network scheme

    ENDHEREDOC
  ) do |args|

    odl_bgpvpn_enabled, network_scheme = args

    # get original network scheme
    orig_endpoints = network_scheme['endpoints']
    orig_roles = network_scheme['roles']
    orig_transformations = network_scheme['transformations']

    # init overridden network scheme
    endpoints       = {}
    roles           = {}
    transformations = []

    # If bgpvpn extensions are enabled br-floating is not needed
    delete_bridges = ['br-prv']
    delete_bridges << 'br-floating' if odl_bgpvpn_enabled

    delete_bridges.each do |bridge|
      transformations << {
        'override'        => bridge,
        'override-action' => 'noop',
      }
    end

    orig_transformations.each do |tf|
      case tf['action']
      when 'add-port'
        transformations << {
          'override'        => tf['name'],
          'override-action' => 'noop',
        } if delete_bridges.include?(tf['bridge'])
      when 'add-patch'
        transformations << {
          'override'        => 'patch-%s:%s' % tf['bridges'],
          'name'            => 'patch__%s--%s' % tf['bridges'],
          'override-action' => 'noop',
        } if delete_bridges.any? { |br| tf['bridges'].include? br }
      end
    end

    if odl_bgpvpn_enabled
      Puppet.debug 'Changing network_scheme for the bgpvpn case'

      roles['neutron/floating'] = 'None' if orig_roles.key?('neutron/floating')
      delete_bridges.each { |br| endpoints[br] = '' }
    else
      Puppet.debug 'Changing network_scheme for the non bgpvpn case'

      BRIDGE_MAPPING = {
        'br-ex'       => 'br-ex-lnx',
        'br-floating' => 'br-ex'
      }

      BRIDGE_MAPPING.each do |orig_br, br|
        transformations << {
          'override' => orig_br,
          'name'     => br,
        }
      end

      orig_transformations.each do |tf|
        transformations << {
          'override' => tf['name'],
          'bridge'   => BRIDGE_MAPPING[tf['bridge']],
        } if BRIDGE_MAPPING.keys.any? { |br| br == tf['bridge'] }
      end

      transformations << {
        'override' => 'patch-br-ex:br-floating',
        'bridges'  => ['br-ex', 'br-ex-lnx'],
      }

      orig_roles.each { |role, br| roles[role] = 'br-ex-lnx' if br == 'br-ex' }

      roles['neutron/private'] = 'br-aux' if orig_roles.key?('neutron/private')
      roles['neutron/floating'] = 'br-ex' if orig_roles.key?('neutron/floating')

      endpoints['br-floating'] = '' if orig_endpoints.key? 'br-floating'

      if orig_endpoints.key? 'br-ex'
        endpoints['br-ex-lnx'] = orig_endpoints['br-ex']
        endpoints['br-ex'] = orig_endpoints['br-floating'] || ''
        endpoints['br-ex']['gateway'] ||= ''
        endpoints['br-ex']['vendor_specific'] ||= {}
      end

      if orig_endpoints.key? 'br-prv'
        endpoints['br-aux'] = orig_endpoints['br-prv']
        endpoints['br-prv'] = ''
      end
    end

    # return overridden network scheme
    {
      'endpoints'       => endpoints,
      'roles'           => roles,
      'transformations' => transformations.map { |tf| tf.merge({'action' => 'override'}) },
    }
  end
end
