                                                    
deploy=11010
for (( i=11001 ; i <= $deploy ; i++ ))
do
 echo stopping $i
 qm stop $i
 echo deleting VM $i
 qm destroy $i --skiplock --purge --destroy-unreferenced-disks
 echo Cloning 104 to $i
 qm clone 104 $i --name sim-lnx-$i --pool lab
 echo Configuring $i Network
 qm set $i --net0 model=virtio,bridge=vmbr0,firewall=1,tag=15
 echo Starting $i
 qm start $i
 sleep 5
done


for (( i=11001 ; i <= $deploy ; i++ ))
do
 echo Renaming $i to sim-rpi-$i
 qm guest exec $i hostname sim-rpi-$i
 qm guest exec $1 rm /usr/local/scripts/vhcached.txt
 qm guest exec $1 /usr/sbin/vhclientx86_64 -t "STOP USING ALL LOCAL"
 sleep 1
 echo Rebooting $i
 qm guest exec $i reboot now
 sleep 5
done




                                                            [ Read 28 lines ]
^G Help          ^O Write Out     ^W Where Is      ^K Cut           ^T Execute       ^C Location      M-U Undo         M-A Set Mark
^X Exit          ^R Read File     ^\ Replace       ^U Paste         ^J Justify       ^/ Go To Line    M-E Redo         M-6 Copy
