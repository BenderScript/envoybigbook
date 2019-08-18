# Enable exit on non 0
set -e

sudo iptables -t mangle -D PREROUTING -p tcp -m socket -j DIVERT
sudo iptables -t mangle -D DIVERT -j MARK --set-mark 1
sudo iptables -t mangle -D DIVERT -j ACCEPT
sudo iptables -t mangle -X DIVERT


sudo ip rule del fwmark 0x1 lookup 100
sudo ip route del local 0.0.0.0/0 dev lo table 100

sudo iptables -t mangle -D PREROUTING -p tcp --dport 80 -j TPROXY --tproxy-mark 0x1/0x1 --on-port 4999
