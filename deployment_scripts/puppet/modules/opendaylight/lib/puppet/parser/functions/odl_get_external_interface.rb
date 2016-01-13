require 'yaml'

module Puppet::Parser::Functions
  newfunction(:odl_get_external_interface, :type => :rvalue) do |args|
    network_scheme = function_hiera(['network_scheme'])
    transformations = network_scheme['transformations']

    ext_interface = transformations.each { |action| break action['name'] if (action['action'] == 'add-port' and action['bridge'] == 'br-ex') }
    ext_interface
  end
end
