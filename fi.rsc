/ip firewall filter
add action=reject chain=input comment="" connection-nat-state="" connection-state=new \
    dst-address-list=!Trusted in-interface-list=WAN protocol=icmp reject-with=icmp-network-unreachable \
    src-address-list=!Trusted
add action=accept chain=forward comment="" connection-state=new in-interface=wireguard1 \
    out-interface-list=WAN
add action=accept chain=input comment="" connection-state=new in-interface=wireguard1
add action=accept chain=input comment="" connection-state=new in-interface-list=\
    LAN
add action=accept chain=input comment="" connection-state=new dst-port=8291 log=yes protocol=tcp
add action=accept chain=input comment="" connection-state=new disabled=yes dst-port=22 \
    in-interface-list=LAN protocol=tcp
add action=accept chain=input comment="" connection-state=new disabled=yes dst-port=23 \
    in-interface-list=LAN protocol=tcp
add action=accept chain=input comment="" connection-state=new disabled=yes dst-port=21 protocol=tcp
add action=accept chain=input comment="" connection-state=\
    established,related
add action=drop chain=input comment="" connection-state=new
add action=fasttrack-connection chain=forward comment=fasttrack connection-state=established,related \
    hw-offload=yes
add action=accept chain=forward comment="" connection-state=new in-interface-list=LAN \
    out-interface-list=WAN
add action=accept chain=forward comment="" connection-state=\
    established,related
add action=accept chain=forward comment="" connection-nat-state=dstnat connection-state=\
    established,related,new
add action=drop chain=forward comment="" connection-state=invalid,new
add action=drop chain=forward comment="" connection-state=new
/
/import file-name=fi.rsc
/file/remove fi.rsc 
