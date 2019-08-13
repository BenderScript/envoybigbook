
sudo iptables -t nat -nvL OUTPUT
sudo iptables -t mangle -nvL PREROUTING
sudo iptables -t mangle -nvL POSTROUTING

printf "\n"
