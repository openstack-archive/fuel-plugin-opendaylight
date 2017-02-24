How to build the plugin from source
===================================

Plugin build process depends on followin list of tools:

* Docker_
* python fuel-plugin-builder_ tool version 4.2.0 or higher
* git
* wget
* ~6 GB of free space

After installing all needed dependencies start build process:

.. code-block:: bash

  $ git clone https://github.com/openstack/fuel-plugin-opendaylight
  $ cd fuel-plugin-opendaylight
  $ fpb --build .

If you want to monitor what actions are performed during plugin build add
``--debug`` option:

.. code-block:: bash

  $ fpb --debug --build .

.. _Docker: https://docker.com/
.. _fuel-plugin-builder: https://pypi.python.org/pypi/fuel-plugin-builder/4.2.0
