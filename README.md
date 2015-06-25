OpenDaylight plugin
===================

This plugin will install OpenDaylight controller and set it as manager for ovs.


Building the plugin
-------------

1. Clone the fuel-plugin repo from:

    ``git clone https://github.com/stackforge/fuel-plugin-opendaylight``

2. Install the Fuel Plugin Builder:

    ``pip install fuel-plugin-builder``

3. Install the [fpm gem](https://github.com/jordansissel/fpm):

    ``gem install fpm``
    
4. Build OpenDaylight Fuel plugin:

   ``fpb --build fuel-plugin-opendaylight/``

5. The *opendaylight-[x.x.x].rpm* plugin package will be created in the plugin folder.
  
6. Move this file to the Fuel Master node with secure copy (scp):

   ``scp opendaylight-[x.x.x].rpm root@<the_Fuel_Master_node_IP address>:/tmp``

7. While logged in Fuel Master install the OpenDaylight plugin:

   ``fuel plugins --install opendaylight-[x.x.x].rpm``

8. Plugin is ready to use and can be enabled on the Settings tab of the Fuel web UI.
