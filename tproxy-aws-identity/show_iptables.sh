sudo iptables -t mangle -nvL PREROUTING

sudo iptables -t mangle -nvL DIVERT

sudo iptables -nvL | more

# Chain PREROUTING (policy ACCEPT 62 packets, 6935 bytes)
# pkts bytes target     prot opt in     out     source               destination
#  178 12008 DIVERT     tcp  --  *      *       0.0.0.0/0            0.0.0.0/0            socket
#    0     0 TPROXY     tcp  --  *      *       0.0.0.0/0            0.0.0.0/0            tcp dpt:80 TPROXY redirect 0.0.0.0:4999 mark 0x1/0x1