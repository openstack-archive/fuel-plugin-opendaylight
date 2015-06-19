#!/bin/bash
crm resource restart p_neutron-dhcp-agent
crm resource restart p_neutron-metadata-agent
crm resource restart p_neutron-l3-agent
