module Puppet::Parser::Functions
  newfunction(:odl_ovsdb_managers, :arity => 1, :type => :rvalue, :doc => <<-'EOS'
    @desc Creates list of ovsdb managers used in ovs-vsctl set-manager command
    @input ['192.168.1.7', ....]
    @return 'tcp:192.168.1.7:6640 ....'
    @example odl_ovsdb_managers($ovsdb_mng)
    EOS
  ) do |args|
    managers = args.flatten.map { |ip| "tcp:#{ip}:6640" }
    managers.join(' ')
  end
end
