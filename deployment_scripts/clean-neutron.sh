#!/bin/bash

source /root/openrc 
router_id=`neutron router-list | grep "network_id" | awk '{print $2}'`
neutron router-gateway-clear $router_id
subnet_id=`neutron router-port-list $router_id | grep "subnet_id" | awk '{print $8}' | awk -F '\"' '{print $2}'`
neutron router-interface-delete $router_id $subnet_id
neutron router-delete $router_id
neutron subnet-delete $subnet_id
neutron net-delete net04
neutron net-delete net04_ext
