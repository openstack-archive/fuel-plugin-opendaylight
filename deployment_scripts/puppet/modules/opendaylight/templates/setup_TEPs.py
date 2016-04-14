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
import logging
import datetime
import urllib
import traceback

try:
    from neutron.openstack.common import jsonutils
except ImportError:
    from oslo_serialization import jsonutils
import json

Open_flow_version = 'Openflow13'
Astute_path = '/etc/astute.yaml'
LOG_PATH = '/var/log/odl_setup_tunnel_endpoints.log'
LOG = logging.getLogger(__name__)
LOG_LEVEL = logging.DEBUG
logging.basicConfig(format='%(asctime)s %(levelname)s: %(message)s',
                    filename=LOG_PATH,
                    datefmt='%Y-%m-%dT:%H:%M:%s', level=LOG_LEVEL)
console = logging.StreamHandler()
console.setLevel(logging.DEBUG)
formatter = logging.Formatter('%(asctime)s %(levelname)s: %(message)s')
console.setFormatter(formatter)
LOG.addHandler(console)


def log_enter_exit(func):

    def inner(self, *args, **kwargs):
        LOG.debug(("Entering %(cls)s.%(method)s "
                   "args: %(args)s, kwargs: %(kwargs)s") %
                  {'cls': self.__class__.__name__,
                   'method': func.__name__,
                   'args': args,
                   'kwargs': kwargs})
        start = datetime.datetime.now()
        ret = func(self, *args, **kwargs)
        end = datetime.datetime.now()
        LOG.debug(("Exiting %(cls)s.%(method)s. "
                   "Spent %(duration)s sec. "
                   "Return %(return)s") %
                  {'cls': self.__class__.__name__,
                   'duration': end - start,
                   'method': func.__name__,
                   'return': ret})
        return ret
    return inner


class ODL_Client(object):

    @log_enter_exit
    def __init__(self, odl_ip, odl_port,
                 user, passw):
        self.url = ("http://%(ip)s:%(port)s/restconf/config" %
                    {'ip': odl_ip,
                     'port': odl_port})
        self.auth = (user, passw)
        self.timeout = 10

    @log_enter_exit
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
            raise ex
        try:
            return json.loads(r.content)
        except Exception as ex:
            LOG.debug("%s" % r)

    # transport zone methods
    @log_enter_exit
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

    @log_enter_exit
    def add_tunnel_endpoint_post(self, tzn, prefix, dpnid, port, ip, gateway):
        vteps = []
        urlPath = 'itm:transport-zones'
        transport_zone_available = True
        try:
            response = self.sendjson('GET', urlPath)
            tz = response['transport-zones']
        except Exception:
            # Fixed cause deprecated
            tunnel_typ = 'vxlan'
            vlanid = 0
            tz = self.create_transport_zone(tzn, tunnel_typ, prefix, vlanid,
                                            gateway)
            transport_zone_available = False
        subnet = tz['transport-zone'][0]['subnets'][0]
        if 'vteps' in subnet:
            vteps = subnet['vteps']
        already_included = False
        vtep = {'dpn-id': dpnid, 'portname': port, 'ip-address': ip}
        for i_vtep in vteps:
            if i_vtep['ip-address'] == ip and not i_vtep['dpn-id'] == dpnid:
                LOG.error("Local_ip already in use %s of DPN %s" %
                          (ip, i_vtep['dpn-id']))
                sys.exit(11)
            if i_vtep == vtep:
                already_included = True
        if already_included:
            LOG.info("vTep: %s already included in the transport zone." % vtep)
            return
        vteps.append(vtep)
        tz['transport-zone'][0]['subnets'][0]['vteps'] = vteps
        if transport_zone_available:
            prefixUrl = urllib.quote(prefix, safe='')
            urlPath = ('itm:transport-zones/transport-zone/'
                       '%(tzn)s/subnets/%(prefixUrl)s/'
                       % {'tzn': tzn,
                          'prefixUrl': prefixUrl})
            self.sendjson('PUT', urlPath,
                          {'subnets': tz['transport-zone'][0]['subnets']})
        else:
            self.sendjson('POST', urlPath, tz)

# HELPER function
@log_enter_exit
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
    @log_enter_exit
    def ovs_ofctl(self, args):
        if Open_flow_version is not '':
            args.append('-O')
            args.append(Open_flow_version)
        return execute(['ovs-ofctl'] + args)

    @log_enter_exit
    def ovs_vsctl(self, args):
        return execute(['ovs-vsctl'] + args)

    @log_enter_exit
    def configure_bridge(self, br, odl_ctrl_ip, of_port):
        self.ovs_vsctl(['--may-exist', 'add-br', br])
        self.ovs_vsctl(['set', 'bridge', br, 'protocols=OpenFlow13'])
        self.ovs_vsctl(['set-controller', br, 'tcp:'+odl_ctrl_ip+':'+of_port])

    @log_enter_exit
    def set_manager(self, ovsdb_managers):
        self.ovs_vsctl(['set-manager'] + ovsdb_managers)

    @log_enter_exit
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
    if len(sys.argv) < 4:
        print("usage: %s <odl_ctrl_ip> <local_ip> <ovsdb_managers>"
              % sys.argv[0])
        sys.exit(10)
    odl_ctrl_ip = sys.argv[1]
    local_ip = sys.argv[2]
    ovsdb_managers = []
    for x in range(3, len(sys.argv)):
        ovsdb_managers.append(sys.argv[x])
    local_port = 'phy0'
    of_port = '6633'

    odl_user = ASTUTE['opendaylight']['metadata']['default_credentials']['user']
    odl_passw = ASTUTE['opendaylight']['metadata']['default_credentials']['password']

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
    ovsc.set_manager(ovsdb_managers)


if __name__ == '__main__':
    try:
        main()
    except Exception as ex:
        LOG.error(ex.message)
        LOG.error(traceback.format_exc())
        LOG.error("For more logs check: %(log_path)s"
                  % {'log_path': LOG_PATH})
        sys.exit(1)


