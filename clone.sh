#!/bin/bash
version=".10"
#--------------------------------------------------------------------------------------------------------------
#Variable Setup - Reading arguments passed to script
command="$1"
start_vmid="$2"
end_vmid="$3"
vlan_id="$4"
bridge_id="$5"
sleep_time="$6"
pool_id="$7"
vm_name="$8"
tpl_id="$9"
#smb_location="$10"
#shr_location="$11"
#--------------------------------------------------------------------------------------------------------------
#Re-Create VMS - Delete, re-clone from template
#Delete and Re-Create the VMs
if [[ $command == "re-create" ]]; then
  for (( i=$start_vmid ; i <= $end_vmid ; i++ ))
    do
     echo stopping $i
     qm stop $i
     echo deleting VM $i
     qm destroy $i --skiplock --purge --destroy-unreferenced-disks
     echo Cloning $tpl_id to $i
     qm clone $tpl_id $i --name $vm_name-$i --pool $pool_id
     echo Starting $i
     qm start $i
     sleep $sleep_time
    done
  #Configuring VM Clones
  for (( i=$start_vmid ; i <= $end_vmid ; i++ ))
    do
     echo Renaming $i to $vm_name-$i
     qm guest exec $i hostname $vm_name-$i
     qm guest exec $i sudo rm /usr/local/scripts/vhcached.txt
     qm guest exec $i sudo mkdir /usr/local/scripts
     qm guest exec $i sudo chmod -R 777 /usr/local/scripts
     qm guest exec $i sudo wget https://raw.githubusercontent.com/solutions-hpe/client-sim/main/install.sh ~/install.sh
     qm guest exec $i sudo mv ./install.sh /usr/local/scripts/install.sh
     qm guest exec $i sudo bash /usr/local/scripts/install.sh --timeout 900
     qm guest exec $i sudo /usr/sbin/vhclientx86_64 -t "STOP USING ALL LOCAL"
     qm guest exec $i smbclient \\$smb_location -N -c 'lcd /usr/local/scripts/; cd '$shr_location'; prompt; mget '$i'.conf'
     qm guest exec $i mv /usr/local/scripts/$i.conf /usr/local/scripts/simulation.conf
     qm guest exec $i shutdown now
    done
  #Sleeping to make sure installation script is completed
  sleep 120
  #Starting VMs after install script has run
  for (( i=$start_vmid ; i <= $end_vmid ; i++ ))
    do
    echo Configuring $i Network
    qm set $i --net0 model=virtio,bridge=$bridge_id,firewall=1,tag=$vlan_id
    qm start $i
    done
fi
#--------------------------------------------------------------------------------------------------------------
#Delete Option - delete all the VMs and cleanup disks
if [[ $command == "delete" ]]; then
  for (( i=$start_vmid ; i <= $end_vmid ; i++ ))
    do
     echo stopping $i
     qm stop $i
     echo deleting VM $i
     qm destroy $i --skiplock --purge --destroy-unreferenced-disks
    done
fi
#--------------------------------------------------------------------------------------------------------------
#Reconfigure VMs - reset the network interface settings, hostname, and clear out VH caches
if [[ $command == "config" ]]; then
  for (( i=$start_vmid ; i <= $end_vmid ; i++ ))
    do
     echo Renaming $i to $vm_name-$i
     qm guest exec $i hostname $vm_name-$i
     qm guest exec $i sudo rm /usr/local/scripts/vhcached.txt
     qm guest exec $i sudo mkdir /usr/local/scripts
     qm guest exec $i sudo chmod -R 777 /usr/local/scripts
     qm guest exec $i sudo wget https://raw.githubusercontent.com/solutions-hpe/client-sim/main/install.sh ~/install.sh
     qm guest exec $i sudo mv ./install.sh /usr/local/scripts/install.sh
     qm guest exec $i sudo bash /usr/local/scripts/install.sh --timeout 900
     qm guest exec $i sudo /usr/sbin/vhclientx86_64 -t "STOP USING ALL LOCAL"
     echo Configuring $i Network
     qm set $i --net0 model=virtio,bridge=$bridge_id,firewall=1,tag=$vlan_id
    done
  #Sleeping to make sure installation script is completed
  sleep 120
  for (( i=$start_vmid ; i <= $end_vmid ; i++ ))
    do
    qm start $i
    done
fi
#--------------------------------------------------------------------------------------------------------------
