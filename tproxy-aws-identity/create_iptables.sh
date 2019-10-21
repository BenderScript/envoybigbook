

# new chain DIVERT in mangle table for marking
sudo iptables -t mangle -N DIVERT
sudo iptables -t mangle -A PREROUTING -p tcp -m socket -j DIVERT
sudo iptables -t mangle -A DIVERT -j MARK --set-mark 1
sudo iptables -t mangle -A DIVERT -j ACCEPT

# Verify

sudo iptables -t mangle --list

# new rule & route for marked
sudo ip rule add fwmark 0x1 lookup 100
sudo ip route add local 0.0.0.0/0 dev lo table 100

# Verify new rules & route
sudo ip route show table 100

sudo ip rule list

# sudo sysctl -w net.ipv4.conf.all.route_localnet=1

sudo iptables -t mangle -A PREROUTING -p tcp --dport 80 -j TPROXY --tproxy-mark 0x1/0x1 --on-port 4999

# sudo iptables -t mangle -I PREROUTING  -m limit --limit 2/min -j LOG
