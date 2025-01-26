#!/bin/bash
command="$1"
start_vmid="$2"
end_vmid="$3"
vlan_id="$4"
bridge_id="$5"
sleep_time="$6"
pool_id="$7"
vm_name="$8"
tpl_id="$9"
  for (( i=$start_vmid ; i <= $end_vmid ; i++ ))
  do
   echo stopping $i
   qm stop $i
   echo deleting VM $i
   qm destroy $i --skiplock --purge --destroy-unreferenced-disks
   echo Cloning $tpl_id to $i
   qm clone $tpl_id $i --name $vm_name-$i --pool $pool_id
   echo Configuring $i Network
   qm set $i --net0 model=virtio,bridge=$bridge_id,firewall=1,tag=$vlan_id
   echo Starting $i
   qm start $i
   sleep $sleep_time
  done

  for (( i=$start_vmid ; i <= $end_vmid ; i++ ))
  do
   echo Renaming $i to $vm_name-$i
   qm guest exec $i hostname $vm_name-$i
   qm guest exec $1 rm /usr/local/scripts/vhcached.txt
   qm guest exec $1 /usr/sbin/vhclientx86_64 -t "STOP USING ALL LOCAL"
   sleep $sleep_time
   echo Rebooting $i
   qm guest exec $i reboot now
   sleep $sleep_time
done
