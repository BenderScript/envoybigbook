# Enable exit on non 0
set -e

sudo iptables -t nat -D OUTPUT 2
sudo iptables -t nat -D OUTPUT 2

sudo iptables -t mangle -D PREROUTING 1
sudo iptables -t mangle -D PREROUTING 1