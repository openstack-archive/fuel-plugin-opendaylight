module Puppet::Parser::Functions
  newfunction(:odl_ovsdb_managers, :type => :rvalue) do |args|
   raise Puppet::ParseError, 'Only one argument with array of IP addresses should be provided!' if args.size != 1
   raise Puppet::ParseError, 'Argument should be array of IP addresses' unless args[0].is_a? Array
   ips = args[0]
   managers = []
   ips.each do |manager|
    managers << "tcp:#{manager}:6640"
   end
   managers.join(' ')
  end
end
