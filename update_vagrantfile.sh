#!/bin/bash

# Include settings file
. webapp_settings.conf

# Change variable IP VM WEB APP in Vagrantfile
echo " >>> Set IP '${IP_VM_WEB_APP}' for VM WEB APP in Vagrantfile.."
sed -i "s/=> \"192.168.1.15\"/=> \"${IP_VM_WEB_APP}\"/g" ./Vagrantfile

# Change variable IP VM DATABASE in Vagrantfile
echo " >>> Set IP '${IP_VM_DATABASE}' for VM DATABASE in Vagrantfile.."
sed -i "s/=> \"192.168.1.16\"/=> \"${IP_VM_DATABASE}\"/g" ./Vagrantfile
echo "ALL DONE!!!"
