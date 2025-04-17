/interface list
add name=WAN
add name=WAN2
add name=LAN

/interface list member
add interface=ether1 list=WAN
add interface=ether2 list=WAN2

/ip firewall nat
add action=src-nat chain=srcnat comment=isp1 connection-mark=ecmp-connection-wan to-addresses=111.111.111.111
add action=src-nat chain=srcnat comment=isp2 connection-mark=ecmp-connection-wan2 to-addresses=222.222.222.222
add action=masquerade chain=srcnat out-interface-list=WAN
add action=masquerade chain=srcnat out-interface-list=WAN2

/ip firewall raw
add action=drop chain=output comment="only output wan" dst-address-list="dst isp1" out-interface-list=!WAN protocol=icmp
add action=drop chain=output comment="only output wan2" dst-address-list="dst isp2" out-interface-list=!WAN2 protocol=icmp

/ip firewall address-list
add address=1.0.0.1 list="dst isp1"
add address=1.1.1.1 list="dst isp1"
add address=8.8.8.8 list="dst isp2"
add address=8.8.4.4 list="dst isp2"

/ip firewall filter
add action=accept chain=forward comment="Allow internet access" connection-state=new in-interface-list=LAN out-interface-list=WAN
add action=accept chain=forward comment="Allow internet access wan2" connection-state=new in-interface-list=LAN out-interface-list=WAN2

/routing table
add fib name=table-route-wan
add fib name=table-route-wan2

/routing rule
add action=lookup-only-in-table disabled=no routing-mark=table-route-wan table=table-route-wan
add action=lookup-only-in-table disabled=no routing-mark=table-route-wan2 table=table-route-wan2

/ip route
add comment="mark isp1" disabled=no distance=1 dst-address=0.0.0.0/0 gateway=111.111.111.111 routing-table=table-route-wan scope=30 suppress-hw-offload=no target-scope=10
add check-gateway=ping comment="Recursive isp1" disabled=no distance=10 dst-address=0.0.0.0/0 gateway=1.1.1.1 routing-table=main scope=30 suppress-hw-offload=no target-scope=11
add comment=isp1 disabled=no distance=1 dst-address=1.1.1.1/32 gateway=111.111.111.111 routing-table=main scope=11 suppress-hw-offload=no target-scope=10
add comment=isp1 disabled=no distance=1 dst-address=1.0.0.1/32 gateway=111.111.111.111 routing-table=main scope=11 suppress-hw-offload=no target-scope=10
add check-gateway=ping comment="Recursive isp1" disabled=no distance=10 dst-address=0.0.0.0/0 gateway=1.0.0.1 routing-table=main scope=30 suppress-hw-offload=no target-scope=11
add comment="mark isp2" disabled=no distance=1 dst-address=0.0.0.0/0 gateway=222.222.222.222 routing-table=table-route-wan2 scope=30 suppress-hw-offload=no target-scope=10
add comment=isp2 disabled=no distance=1 dst-address=8.8.8.8/32 gateway=222.222.222.222 routing-table=main scope=11 suppress-hw-offload=no target-scope=10
add comment=isp2 disabled=no distance=1 dst-address=8.4.4.8/32 gateway=222.222.222.222 routing-table=main scope=11 suppress-hw-offload=no target-scope=10
add check-gateway=ping comment="Recursive isp2" disabled=no distance=20 dst-address=0.0.0.0/0 gateway=8.8.8.8 routing-table=main scope=30 suppress-hw-offload=no target-scope=11
add check-gateway=ping comment="Recursive isp2" disabled=no distance=20 dst-address=0.0.0.0/0 gateway=8.4.4.8 routing-table=main scope=30 suppress-hw-offload=no target-scope=11
	
	/ip/firewall/mangle
	add action=log chain=prerouting comment=ISP1 disabled=yes
add action=mark-connection chain=prerouting comment=wan/input/provider connection-state=new in-interface-list=WAN new-connection-mark=connection-wan passthrough=no
add action=mark-routing chain=output comment=wan/output/provider connection-mark=connection-wan new-routing-mark=table-route-wan passthrough=no
add action=mark-routing chain=output comment=wan/output/provider/ip/isp1 new-routing-mark=table-route-wan passthrough=no src-address=111.111.111.111
add action=mark-routing chain=prerouting comment=wan/prerouting/provider connection-mark=connection-wan in-interface-list=!WAN new-routing-mark=table-route-wan passthrough=no
add action=mark-connection chain=postrouting comment=wan/ecmp/provider connection-state=new new-connection-mark=ecmp-connection-wan out-interface-list=WAN passthrough=no
add action=mark-routing chain=prerouting comment=wan/ecmp/provider connection-mark=ecmp-connection-wan in-interface-list=!WAN new-routing-mark=table-route-wan passthrough=no
add action=log chain=postrouting comment=ISP2 disabled=yes
add action=mark-connection chain=prerouting comment=wan/input/provider connection-state=new in-interface-list=WAN2 new-connection-mark=connection-wan2 passthrough=no
add action=mark-routing chain=output comment=wan/output/provider connection-mark=connection-wan2 new-routing-mark=table-route-wan2 passthrough=no
add action=mark-routing chain=output comment=wan/output/provider/ip/isp2 new-routing-mark=table-route-wan2 passthrough=no src-address=222.222.222.222
add action=mark-routing chain=prerouting comment=wan/prerouting/provider connection-mark=connection-wan2 in-interface-list=!WAN2 new-routing-mark=table-route-wan2 passthrough=no
add action=mark-connection chain=postrouting comment=wan/ecmp/provider connection-state=new new-connection-mark=ecmp-connection-wan2 out-interface-list=WAN2 passthrough=no
add action=mark-routing chain=prerouting comment=wan/ecmp/provider connection-mark=ecmp-connection-wan2 in-interface-list=!WAN2 new-routing-mark=table-route-wan2 passthrough=no

/ip dhcp-client
add add-default-route=no comment=isp1 default-route-tables=main interface=ether1 script=":global ipether1 [:pick [/ip address get [find interface=ether1]\
    \_address] 0 ([:find [/ip address get [find interface=ether1] address] \"/\"])]\
    \n\r\
    \n\r\
    \n:global gwether1 [/ip dhcp-client get [find interface=\"ether1\"] gateway]\r\
    \n\r\
    \n\r\
    \n/ip route set [find where comment=\"mark isp1\"] gateway=\$gwether1\r\
    \n\r\
    \n/ip route set [find where comment=\"isp1\"] gateway=\$gwether1\r\
    \n\r\
    \n/ip/fi/mangle/ set [find where comment=\"wan/output/provider/ip/isp1\"] src-address=\$ipether1\r\
    \n\r\
    \n/ip/fi/nat/ set [find where comment=\"isp1\"] to-addresses=\$ipether1\r\
    \n" use-peer-dns=no
add add-default-route=no comment=isp2 default-route-tables=main interface=ether2 script=":global ipether2 [:pick [/ip address get [find interface=ether2]\
    \_address] 0 [:find [/ip address get [find interface=ether2] address] \"/\"]];\
    \n\r\
    \n\r\
    \n:global gwether2 [/ip dhcp-client get [find interface=\"ether2\"] gateway]\r\
    \n\r\
    \n\r\
    \n/ip route set [find where comment=\"mark isp2\"] gateway=\$gwether2\r\
    \n\r\
    \n/ip route set [find where comment=\"isp2\"] gateway=\$gwether2   \r\
    \n\r\
    \n\r\
    \n/ip/fi/mangle/ set [find where comment=\"wan/output/provider/ip/isp2\"] src-address=\$ipether2\r\
    \n\r\
    \n/ip/fi/nat/ set [find where comment=\"isp2\"] to-addresses=\$ipether2\r\
    \n" use-peer-dns=no