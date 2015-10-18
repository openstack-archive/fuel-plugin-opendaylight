#!/bin/bash

source /root/openrc

#allow ssh login
nova secgroup-add-rule default  tcp 22 22 0.0.0.0/0
#allow ping
nova secgroup-add-rule default icmp -1 -1 0.0.0.0/0
#needed for geiing IP from dnsmasq (dhcp)
nova secgroup-add-rule default  udp 68 68 0.0.0.0/0
#vnf template: 512Mbytes RAM, 3Gbytes disk, 1 CPU
nova flavor-create m1.vnf 6 512 3 1
