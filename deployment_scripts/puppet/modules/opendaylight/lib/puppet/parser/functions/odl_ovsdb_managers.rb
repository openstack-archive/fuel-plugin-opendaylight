module Puppet::Parser::Functions
  newfunction(:odl_ovsdb_managers, :arity => 1, :type => :rvalue) do |args|

    managers = args.flat_map { |ip| "tcp:#{ip}:6640" }
    managers.join(' ')

  end
end
