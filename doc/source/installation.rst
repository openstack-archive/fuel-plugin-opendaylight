Installation
============

#. Upload the plugin .rpm to the Fuel master node.

#. Install the plugin with the ``fuel`` command-line tool:

   .. code-block:: bash

     [root@nailgun ~] fuel plugins --install opendaylight-1.0-1.0.0-1.noarch.rpm


Uninstallation
==============

The plugin can be uninstalled only when there are no OpenStack envrionments
that are using it.

Uninstall the plugin by running following command:

  .. code-block:: bash

    [root@nailgun ~] fuel plugins --remove opendaylight==1.0.0
