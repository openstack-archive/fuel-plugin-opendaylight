module Puppet::Parser::Functions
  newfunction(:odl_package_name, :arity => 1, :type => :rvalue, :doc => <<-EOS
    @desc Check if feature which require experimental odl is enabled.
    @return String with odl deb package name.
    EOS
   ) do |args|
    odl_settings = args[0]
    experimental_odl = odl_settings['metadata']['use_experimental_odl']
    if experimental_odl.is_a?(Array) and experimental_odl.any? { |feature| odl_settings[feature] }
      odl_settings['metadata']['experimental_odl_deb']
    else
      odl_settings['metadata']['odl_deb']
    end
  end
end
