

# TPROXY target options:
#  --on-port port            Redirect connection to port, or the original port if 0
#  --on-ip ip                Optionally redirect to the given IP
#  --tproxy-mark value[/mask]        Mark packets with the given value/mask

# new chain DIVERT in mangle table for marking
sudo iptables -t mangle -N DIVERT
sudo iptables -t mangle -A PREROUTING -p tcp -m socket -j DIVERT
sudo iptables -t mangle -A DIVERT -j MARK --set-mark 1
sudo iptables -t mangle -A DIVERT -j ACCEPT

# Verify

#ubuntu:~$ sudo iptables --table mangle --list
#Chain PREROUTING (policy ACCEPT)
#target     prot opt source               destination
#DIVERT     tcp  --  anywhere             anywhere             socket
#
#Chain INPUT (policy ACCEPT)
#target     prot opt source               destination
#
#Chain FORWARD (policy ACCEPT)
#target     prot opt source               destination
#
#Chain OUTPUT (policy ACCEPT)
#target     prot opt source               destination
#
#Chain POSTROUTING (policy ACCEPT)
#target     prot opt source               destination
#
#Chain DIVERT (1 references)
#target     prot opt source               destination
#MARK       all  --  anywhere             anywhere             MARK set 0x7
#ACCEPT     all  --  anywhere             anywhere


# new rule & route for marked
sudo ip rule add fwmark 0x1 lookup 100
sudo ip route add local 0.0.0.0/0 dev lo table 100

# Verify new rules & route
# ip route show table 100

#ubuntu:~$ ip rule list
#0:	from all lookup local
#32765:	from all fwmark 0x1 lookup 100
#32766:	from all lookup main
#32767:	from all lookup default


#ubuntu:~$ ip route show table all
#local default dev lo table 123 scope host
#default via 172.31.16.1 dev eth0 proto dhcp src 172.31.22.139 metric 100
#172.17.0.0/16 dev docker0 proto kernel scope link src 172.17.0.1 linkdown
#172.18.0.0/16 dev br-7f6640f4539e proto kernel scope link src 172.18.0.1 linkdown
#172.31.16.0/20 dev eth0 proto kernel scope link src 172.31.22.139
#172.31.16.1 dev eth0 proto dhcp scope link src 172.31.22.139 metric 100
#broadcast 127.0.0.0 dev lo table local proto kernel scope link src 127.0.0.1
#local 127.0.0.0/8 dev lo table local proto kernel scope host src 127.0.0.1
#local 127.0.0.1 dev lo table local proto kernel scope host src 127.0.0.1
#broadcast 127.255.255.255 dev lo table local proto kernel scope link src 127.0.0.1
#broadcast 172.17.0.0 dev docker0 table local proto kernel scope link src 172.17.0.1 linkdown
#local 172.17.0.1 dev docker0 table local proto kernel scope host src 172.17.0.1
#broadcast 172.17.255.255 dev docker0 table local proto kernel scope link src 172.17.0.1 linkdown
#broadcast 172.18.0.0 dev br-7f6640f4539e table local proto kernel scope link src 172.18.0.1 linkdown
#local 172.18.0.1 dev br-7f6640f4539e table local proto kernel scope host src 172.18.0.1
#broadcast 172.18.255.255 dev br-7f6640f4539e table local proto kernel scope link src 172.18.0.1 linkdown
#broadcast 172.31.16.0 dev eth0 table local proto kernel scope link src 172.31.22.139
#local 172.31.22.139 dev eth0 table local proto kernel scope host src 172.31.22.139
#broadcast 172.31.31.255 dev eth0 table local proto kernel scope link src 172.31.22.139
#local ::1 dev lo proto kernel metric 256 pref medium
#fe80::/64 dev eth0 proto kernel metric 256 pref medium
#local ::1 dev lo table local proto kernel metric 0 pref medium
#local fe80::40:ff:fe46:51d3 dev eth0 table local proto kernel metric 0 pref medium
#ff00::/8 dev eth0 table local metric 256 pref medium

sudo sysctl -w net.ipv4.conf.all.route_localnet=1

# sudo iptables -t mangle -A PREROUTING -p tcp --dport 80 -j TPROXY --tproxy-mark 0x1/0x1 --on-port 4999

sudo iptables -t mangle -A PREROUTING -p tcp --dport 80 -j TPROXY --tproxy-mark 0x1/0x1 --on-port 4999

sudo iptables -t mangle -I PREROUTING -m limit --limit 2/min -j LOG

sudo iptables -t mangle -nvL PREROUTING