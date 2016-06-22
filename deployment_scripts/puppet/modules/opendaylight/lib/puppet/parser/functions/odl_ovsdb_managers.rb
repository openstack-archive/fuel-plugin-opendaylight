module Puppet::Parser::Functions
  newfunction(:odl_ovsdb_managers, :arity => 1, :type => :rvalue) do |args|

    ips = args.flatten!
    managers = ips.map { |ip| "tcp:#{ip}:6640" }
    managers.join(' ')

  end
end
