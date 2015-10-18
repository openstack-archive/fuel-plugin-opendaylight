#!/bin/bash

source /root/openrc

#allow ssh login
nova secgroup-add-rule default tcp 22 22 0.0.0.0/0
#allow ping
nova secgroup-add-rule default icmp -1 -1 0.0.0.0/0
#vnf template: 512Mbytes RAM, 3Gbytes disk, 1 CPU
nova flavor-create m1.vnf 6 512 3 1
#vnf core image
glance image-create\
 --name="imgvnf"\
 --is-public=true\
 --disk-format=qcow2\
 --container-format=bare\
 --location http://uec-images.ubuntu.com/releases/14.04/release/ubuntu-14.04-server-cloudimg-amd64-disk1.img
