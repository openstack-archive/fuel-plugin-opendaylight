## 0.8.0

  - Support MOS 8.0.
  - Move ODL installation and configuration
    to main phase of deployment.
  - L3 traffic managed by ODL possible when vxlan
    tunneling is used.
  - Include snapshot of OpenDaylight Beryllium,
    stable version not available at this moment.
  - Get rid of hardcoded configuration related to specific ODL version.
    Now plugin is more elastic and should support a broader
    number of ODL versions.
  - odl_network_scheme function overrided standard network scheme
    so custom network templates are not required.
  - ODL is no longer patched to use br-floating bridge.


## 0.7.0

  - Support for MOS 7.0
  - Include OpenDaylight Lithium SR2
  - Introduce separate role for ODL controller
