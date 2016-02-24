'''
Created on Feb 19, 2016

This script created the tunnel endpoints in odl when vpnservice feature
is used

@author: enikher
'''
from subprocess import Popen, PIPE
import requests
import os
import yaml
import sys

try:
    from neutron.openstack.common import jsonutils
except ImportError:
    from oslo_serialization import jsonutils
import json

Open_flow_version = 'Openflow13'
Astute_path = '/etc/astute.yaml'


class LOG():
    def debug(self, msg):
        print msg

    def error(self, msg):
        print msg


LOG = LOG()


class ODL_Client(object):

    def __init__(self, odl_ip, odl_port,
                 user, passw):
        self.url = ("http://%(ip)s:%(port)s/restconf/config" %
                    {'ip': odl_ip,
                     'port': odl_port})
        self.auth = (user, passw)
        self.timeout = 10

    def sendjson(self, method, urlpath, obj=None):
        """Send json to the OpenDaylight controller."""
        headers = {'Content-Type': 'application/json'}
        data = jsonutils.dumps(obj, indent=2) if obj else None
        url = '/'.join([self.url, urlpath])
        LOG.debug("Sending METHOD (%(method)s) URL (%(url)s) JSON (%(obj)s)" %
                  {'method': method, 'url': url, 'obj': obj})
        r = requests.request(method, url=url,
                             headers=headers, data=data,
                             auth=self.auth, timeout=self.timeout)
        try:
            r.raise_for_status()
        except Exception as ex:
            LOG.error("Error Sending METHOD (%(method)s) URL (%(url)s)"
                      "JSON (%(obj)s) return: %(r)s ex: %(ex)s; "
                      "Message: %(message)s" %
                      {'method': method, 'url': url, 'obj': obj, 'r': r,
                       'ex': ex, 'message': r.text})
            return r, None
        try:
            return r, json.loads(r.content)
        except Exception:
            LOG.debug("%s" % r)
            return r, None

    # transport zone methods
    def create_transport_zone(self, name, tun_type,
                              prefix, vlanid, gateway):
        tz = {'transport-zone': [
                {'zone-name': name,
                 'tunnel-type': 'odl-interface:tunnel-type-'+tun_type,
                 'subnets': [{'prefix': prefix,
                              'vlan-id': vlanid,
                              'gateway-ip': gateway,
                              'vteps': []}]
                 }
                ]
              }
        return tz

    def add_tunnel_endpoint_post(self, tzn, prefix, dpnid, port, ip, gateway):
        vteps = []
        urlPath = 'itm:transport-zones'
        response = self.sendjson('GET', urlPath)
        if response[1] is not None:
            tz = response[1]['transport-zones']
        else:
            # Fixed cause deprecated
            tunnel_typ = 'vxlan'
            vlanid = 0
            tz = self.create_transport_zone(tzn, tunnel_typ, prefix, vlanid,
                                            gateway)
        subnet = tz['transport-zone'][0]['subnets'][0]
        if 'vteps' in subnet:
            vteps = subnet['vteps']
        for i_vtep in vteps:
            if i_vtep['ip-address'] == ip and not i_vtep['dpn-id'] == dpnid:
                print("Local_ip already in use %s of DPN %s" %
                      (ip, i_vtep['dpn-id']))
                sys.exit(11)
        vtep = {'dpn-id': dpnid, 'portname': port, 'ip-address': ip}
        vteps.append(vtep)
        tz['transport-zone'][0]['subnets'][0]['vteps'] = vteps

        # There is a bug in ODL that a put does not update the tunel
        # endpoints. So we need to delete it and post it again.
        # If new blades are added into an running env that could break
        # the other end points
        # https://bugs.opendaylight.org/show_bug.cgi?id=5422
        self.sendjson('DELETE', urlPath)
        response = self.sendjson('POST', urlPath, tz)
        return response[1]


# HELPER function
def execute(cmd, stdin="", rc_wanted=[0]):
    p = Popen(cmd, stdin=PIPE, stdout=PIPE, stderr=PIPE)
    output, err = p.communicate(stdin)
    rc = p.returncode
    if rc not in rc_wanted:
        raise Exception("Command: %(cmd)s exit with rc: %(rc)s "
                        "Output: %(output)s err: %(err)s" %
                        {'cmd': cmd, 'rc': rc, 'output': output,
                         'err': err})
    return output, err, rc


class ovs_client():
    def ovs_ofctl(self, args):
        if Open_flow_version is not '':
            args.append('-O')
            args.append(Open_flow_version)
        return execute(['ovs-ofctl'] + args)

    def ovs_vsctl(self, args):
        return execute(['ovs-vsctl'] + args)

    def configure_bridge(self, br, odl_ctrl_ip, of_port):
        self.ovs_vsctl(['--may-exist', 'add-br', br])
        self.ovs_vsctl(['set', 'bridge', br, 'protocols=OpenFlow13'])
        self.ovs_vsctl(['set-controller', br, 'tcp:'+odl_ctrl_ip+':'+of_port])

    def get_dpid(self, brname):
        dpId = -1
        result = self.ovs_vsctl(['get', 'Bridge', brname, 'datapath_id'])
        if result[2] is 0:
            hexDpId = result[0][1:-2]
            dpId = int(hexDpId, 16)
            # TODO: if dpId is negative, convert to unsigned
        return dpId


def main():
    if os.path.isfile(Astute_path):
        with open(Astute_path, 'r') as f:
            ASTUTE = yaml.load(f)
    if len(sys.argv) < 3:
        print("usage: %s <odl_ctrl_ip> <local_ip>" % sys.argv[0])
        sys.exit(10)
    odl_ctrl_ip = sys.argv[1]
    local_ip = sys.argv[2]
    local_port = 'phy0'
    of_port = '6633'

    # FIXME: That should come from fuel at some point in time
    odl_user = 'admin'
    odl_passw = 'admin'

    odl_ha_ip = ASTUTE['network_metadata']['vips']['management']['ipaddr']
    odl_rest_api_port = ASTUTE['opendaylight']['rest_api_port']
    prefix = ASTUTE['private_network_range']
    gateway = ASTUTE['opendaylight']['bgpvpn_gateway']

    # Configure OVS
    ovsc = ovs_client()
    ovsc.configure_bridge('br-int', odl_ctrl_ip, of_port)
    dpid = ovsc.get_dpid('br-int')

    # Configure ODL
    odlc = ODL_Client(odl_ha_ip, odl_rest_api_port, odl_user, odl_passw)
    # There is only one transport zone at the moment
    odlc.add_tunnel_endpoint_post('TZA', prefix, dpid, local_port,
                                  local_ip, gateway)


if __name__ == '__main__':
    main()


